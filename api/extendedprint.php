<?php
class ZabrusExtendedPrintController extends DevblocksControllerExtension {
	const ID = 'zabrus.controller.extendedprint';
	
	/*
	 * Request Overload
	 */
	function handleRequest(DevblocksHttpRequest $request) {
		$worker = CerberusApplication::getActiveWorker();
		
		if(empty($worker)) return;
		// Check ACL permissions
		if(!$worker->hasPriv('zabrus.extendedprint.enabled')) return;
		
		$stack = $request->path;
		array_shift($stack); // print
		@$object = strtolower(array_shift($stack)); // ticket|message|etc
		
		$tpl = DevblocksPlatform::getTemplateService();
		$tpl->cache_lifetime = 0;
		
		$settings = DevblocksPlatform::getPluginSettingsService();
		$tpl->assign('settings', $settings);
		
		$translate = DevblocksPlatform::getTranslationService();
		$tpl->assign('translate', $translate);
		
		$teams = DAO_Group::getAll();
		$tpl->assign('teams', $teams);
		
		$buckets = DAO_Bucket::getAll();
		$tpl->assign('buckets', $buckets);
		
		$workers = DAO_Worker::getAll();
		$tpl->assign('workers', $workers);

		// Security
		$active_worker = CerberusApplication::getActiveWorker();
		$active_worker_memberships = $active_worker->getMemberships();
		
		@$id = array_shift($stack);
		@$ticket = is_numeric($id) ? DAO_Ticket::get($id) : DAO_Ticket::getTicketByMask($id);

		// Zabrus Extended Print begin 
		$fields = DAO_CustomField::getByContext(CerberusContexts::CONTEXT_TICKET);
		//print_r ($fields);

		// Get the custom fields and their values for this ticket
		$custom_fields = DAO_CustomField::getByContext(CerberusContexts::CONTEXT_TICKET);
		$tpl->assign('custom_fields', $custom_fields);
		
		// DEBUG:
		// print_r($custom_fields );
		// echo '<hr>';
		// print_r($custom_field_values );
		// echo '<hr>';
		
		$address = DAO_Address::getWhere(sprintf("id = %d", $ticket->first_wrote_address_id));
		
		$org_id = $address[$ticket->first_wrote_address_id]->contact_org_id;
		if(null != ($org = DAO_ContactOrg::getWhere(sprintf("id = %d", $org_id))))
			$tpl->assign('org', $org[$org_id]);

		$custom_field_values = DAO_CustomFieldValue::getValuesByContextIds(CerberusContexts::CONTEXT_TICKET, $ticket->id);
		if(isset($custom_field_values[$ticket->id]))
			$tpl->assign('custom_field_values', $custom_field_values[$ticket->id]);
			
		// Calculate a ticket lifetime estimate (not accurate, as it does not reflect status changes, re-opens etc.)
		// ... it's more like a conversation time span 
		$day = 60*60*24;
		$tpl->assign('life_time', floor(($ticket->updated_date - $ticket->created_date + $day)/($day)));

		// Display and print dialog control
		$personal_print_settings = ZabrusExtendedPrintSettings::getSettings (ZabrusExtendedPrintSettings::PERSONAL_PRINT_SETTINGS);
		$global_print_settings = ZabrusExtendedPrintSettings::getSettings (ZabrusExtendedPrintSettings::GLOBAL_PRINT_SETTINGS);
		$tpl->assign ('print_settings', $personal_print_settings[ZabrusExtendedPrintSettings::USE_PERSONAL_SETTINGS] ? $personal_print_settings : $global_print_settings);
		
		// CONTEXT LINKS
		
		// First we have to find what kind of contexts are linked
		$contexts = DAO_ContextLink::getDistinctContexts('cerberusweb.contexts.ticket', $ticket->id);

		// Let's find specific links for each contect type and aggregate the results in an array
		$context_items = array();
		foreach ($contexts as $context_item) {
			$ctx = DAO_ContextLink::getContextLinks(CerberusContexts::CONTEXT_TICKET, array($ticket->id), $context_item);
			$context_items += $ctx[$ticket->id];	
		}
		
		$tpl->assign ('linked_items', $context_items);
		
		$convo_timeline = array();
		$messages = $ticket->getMessages();		
		foreach($messages as $message_id => $message) { /* @var $message Model_Message */
			$key = $message->created_date . '_m' . $message_id;
			// build a chrono index of messages
			$convo_timeline[$key] = array('m',$message_id);
		}				
		
		$comments = DAO_Comment::getByContext(CerberusContexts::CONTEXT_TICKET, $ticket->id);
		arsort($comments);
		$tpl->assign('comments', $comments);
		
		// build a chrono index of comments
		foreach($comments as $comment_id => $comment) { /* @var $comment Model_Comment */
			$key = $comment->created . '_c' . $comment_id;
			$convo_timeline[$key] = array('c',$comment_id);
		}

		ksort($convo_timeline);
		
		$tpl->assign('convo_timeline', $convo_timeline);

		// Comment parent addresses
		$comment_addresses = array();
		foreach($comments as $comment) { /* @var $comment Model_Comment */
			$address_id = intval($comment->address_id);
			if(!isset($comment_addresses[$address_id])) {
				$address = DAO_Address::get($address_id);
				$comment_addresses[$address_id] = $address;
			}
		}
		$tpl->assign('comment_addresses', $comment_addresses);				
		
		// Message Notes
		$notes = DAO_Comment::getByContext(CerberusContexts::CONTEXT_TICKET, $ticket->id);
		$message_notes = array();
		// Index notes by message id
		if(is_array($notes))
		foreach($notes as $note) {
			if(!isset($message_notes[$note->context_id]))
				$message_notes[$note->context_id] = array();
			$message_notes[$note->context_id][$note->id] = $note;
		}
		$tpl->assign('message_notes', $message_notes);
		
		// Make sure we're allowed to view this ticket or message
		if(!isset($active_worker_memberships[$ticket->group_id])) {
			echo "<H1>" . $translate->_('common.access_denied') . "</H1>";
			return;
		}
		
		// Watchers
		$context_watchers = CerberusContexts::getWatchers(CerberusContexts::CONTEXT_TICKET, $ticket->id);
		$tpl->assign('context_watchers', $context_watchers);

		$tpl->assign('ticket', $ticket);
		
		$tpl->display('devblocks:zabrus.extendedprint::print_ticket.tpl');
				
	}
	
};

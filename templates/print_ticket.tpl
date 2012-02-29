<html>
<head>
	<title>Ticket #{$ticket->mask}: {$ticket->subject} - {$settings->get('cerberusweb.core','helpdesk_title','')}</title>
	<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset={$smarty.const.LANG_CHARSET_CODE}">
	<!-- Applying default built-in style sheet from the file system -->
	<link type="text/css" rel="stylesheet" href="{devblocks_url}c=resource&p=zabrus.extendedprint&f=css/extendedprint.css{/devblocks_url}?v={$smarty.const.APP_BUILD}">
	{if $print_settings['custom_styles']}
	<!-- Get the custom style overrides from the database -->
	<style>
		{$print_settings['custom_style_sheet']}
	</style>
	{/if}
	<style>
	</style>
</head>

<body {if $print_settings['open_print_dialog']}onload="window.print();"{/if}>

{if $ticket->is_deleted}
   {assign var=status_class value='deleted'}
{elseif $ticket->is_closed}
   {assign var=status_class value='closed'}
{elseif $ticket->is_waiting}
   {assign var=status_class value='waiting'}
{else}
   {assign var=status_class value='open'}
{/if}

<h2 class="mask">{$ticket->mask}</h2>
<h2 class="status status-{$status_class}">{if $ticket->is_deleted}{$translate->_('status.deleted')}{elseif $ticket->is_closed}{$translate->_('status.closed')}{elseif $ticket->is_waiting}{$translate->_('status.waiting')}{else}{$translate->_('status.open')}{/if}</h2>
<h2 class="subject">{$ticket->subject}</h2>

{if !empty($org)}
	{assign var=org_name value=$org->name}
	{assign var=org_country value=$org->country}
	<h3>{$org_name} ({$org_country})</h3>
{/if}

{assign var=ticket_group_id value=$ticket->grgroupid}
{assign var=ticket_team value=$teams.$ticket_team_id}
{assign var=ticket_category_id value=$ticket->category_id}
{assign var=ticket_team_category_set value=$team_categories.$ticket_group_id}
{assign var=ticket_category value=$ticket_team_category_set.$ticket_category_id}

<hr>

<table border="0" width="100%">
	<tr>
		<td><b>Created:</b> {$ticket->created_date|date_format}</td>  <td class="right"><b>Team:</b> {$teams.$ticket_group_id->name}</td> 
	</tr>
	<tr>
		<td><b>Updated:</b> {$ticket->updated_date|date_format}</td>  <td class="right"><b>Bucket:</b> {if !empty($ticket_category_id)}{$buckets.$ticket_category_id->name}{else}Inbox{/if}</td> 
	</tr>
	<tr>
		<td>
			<b>Age:</b> {$life_time} day(s)
		</td>
		<td class="right">
			{if !empty($context_watchers)}
				<b>{'common.watchers'|devblocks_translate|capitalize}:</b> 
				{foreach from=$context_watchers item=context_worker name=context_watchers}
				{$context_worker->getName()}{if !$smarty.foreach.context_watchers.last}, {/if}
				{/foreach}	
			{/if}
		</td> 
	</tr>
	<tr>
		<td>&nbsp;</td> <td class="right"><b>Internal ID:</b> {$ticket->id}</td>
	</tr>
</table>

<br>

<!-- CUSTOM FIELDS-->

{if !empty($custom_fields) && !empty($custom_field_values)}
<hr>
<table cellpadding="10" cellspacing=0 border="0" class="custom-fields">
{foreach from=$custom_fields item=field name=fields}
	{if (0==$field->group_id) || ($ticket_group_id == $field->group_id)}
		{assign var=n value=$field->id}
		{assign var=ftype value=$field->type}
	    {assign var=fvalue value=$custom_field_values[$n]}
	    
	    {if !empty($fvalue)}
		<tr>
		    <td class="custom-field"><b>{$field->name}: </b> </td>
		    {if $ftype == 'E'}
				{$fvalue=$custom_field_values[$n]|date_format}
		    {elseif $ftype == 'W'}
				{if !empty($workers.$fvalue)}
					{$fvalue=$workers.$fvalue->getName()}
				{/if}
		   {/if}
		   <td class="custom-field-value">{$fvalue}</td>
		</tr>
		{/if}
	{/if}
{/foreach}
</table>
{/if}                                                                        

<!-- LINKED ENTITIES -->

{if !empty($linked_items)}
	<hr>
	<h3>{'common.links'|devblocks_translate|capitalize}:</h3>
	<ul class="links">
	{foreach from=$linked_items item=link name=links}
			{assign var=link_value value=$link->context_id}
			<li>
			{if  $link->context == CerberusContexts::CONTEXT_WORKER}
				{$_w = DAO_Worker::get($link->context_id)}
				{'common.worker'|devblocks_translate|capitalize}: <b>{$_w->first_name} {$_w->last_name}</b> (<span class="email">{$_w->email}</span>)
			{elseif  $link->context == CerberusContexts::CONTEXT_ORG}
				{$_w = DAO_ContactOrg::get($link->context_id)}
				{'contact_org.name'|devblocks_translate|capitalize}: <b>{$_w->name}</b> ({$_w->country})
			{elseif  $link->context == 'cerberusweb.contexts.feed.item'}
				{$_w = DAO_FeedItem::get($link->context_id)}
				{$_feed = DAO_Feed::get($_w->feed_id)}
				{$_feed->name}: <b>{$_w->title}</b>
			{else}
				{$link->context}: ID=<b>$link->context_id</b> ({'extendedprint.ui.uknowncontexttype'|devblocks_translate|capitalize})
			{/if}
			</li>
	{/foreach}
	</ul>                                                                              
{/if}

{* Messages *}
{if !$print_settings['hide_messages']}
	{assign var=messages value=$ticket->getMessages()}
	{foreach from=$convo_timeline item=convo_set name=items}
		<hr>
		{if $convo_set.0=='m'}
			{assign var=message_id value=$convo_set.1}
			{assign var=message value=$messages.$message_id}
			{assign var=headers value=$message->getHeaders()}
				{if isset($headers.subject)}<b>Subject:</b> {$headers.subject}<br>{/if}
				{if isset($headers.from)}<b>From:</b> {$headers.from}<br>{/if}
				
				{assign var=_id value = $headers.from->address_id}
				<b>Address ID:</b> {$_id} <br>
				
				{if isset($headers.date)}<b>Date:</b> {$headers.date|nl2br nofilter}<br>{/if}
				{if isset($headers.to)}<b>To:</b> {$headers.to}<br>{/if}
				{if isset($headers.cc)}<b>Cc:</b> {$headers.cc}<br>{/if}
				<br>
				<div class="printed-message">
				{if $print_settings['show_quotes']}
					{$message->getContent()|trim|nl2br nofilter}
				{else}
					{$message->getContent()|trim|nl2br|devblocks_hyperlinks|devblocks_hideemailquotes nofilter}
				{/if}
				<br><br>
				</div>
				
				{if isset($message_notes.$message_id) && is_array($message_notes.$message_id)}
					{foreach from=$message_notes.$message_id item=note name=notes key=note_id}
							
						<div class="message-notes">
							<b>[{$translate->_('display.ui.sticky_note')|capitalize}] </b>
							{if 1 == $note->type}
								<b>[warning]:</b>&nbsp;
							{elseif 2 == $note->type}
								<b>[error]:</b>&nbsp;
							{else}
								<br><b>From: </b>
								{assign var=note_worker_id value=$note->worker_id}
								{if $workers.$note_worker_id}
									{if empty($workers.$note_worker_id->first_name) && empty($workers.$note_worker_id->last_name)}&lt;{$workers.$note_worker_id->email}&gt;{else}{$workers.$note_worker_id->getName()}{/if}&nbsp;
								{else}
									(Deleted Worker)&nbsp;
								{/if}
							{/if}
							<br>
							<b>{$translate->_('message.header.date')|capitalize}:</b> {$note->created|devblocks_date}<br>
							{if !empty($note->content)}{$note->content}{/if}
						</div>
					{/foreach}
				{/if}
				<br>		
		{elseif $convo_set.0=='c'}
			{assign var=comment_id value=$convo_set.1}
			{assign var=comment value=$comments.$comment_id}
			{assign var=comment_address value=$comment->getAddress()}
			
			<b>[{$translate->_('common.comment')|capitalize}]</b><br>
			<b>From:</b>{if empty($comment_address->first_name) && empty($comment_address->last_name)}&lt;{$comment_address->email}&gt;{else}{$comment_address->getName()}{/if}<br>
		
			{if isset($comment->created)}<b>{$translate->_('message.header.date')|capitalize}:</b> {$comment->created|devblocks_date}<br>{/if}
			<br>
			{$comment->comment|trim}
			<br>
		{/if}
	{/foreach}
{/if}

<p class="small">[Printed by devblocks:zabrus.extendedprint - zabrus.com]</p>

</body>
</html>

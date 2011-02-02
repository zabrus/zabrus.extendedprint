<button 
	type="button" 
	onclick="document.frmPrint.action='{devblocks_url}c=extendedprint&a=ticket&id={$ticket->mask}{/devblocks_url}';document.frmPrint.submit();"
	><span 
		class="cerb-sprite sprite-printer">
		</span> {$translate->_('extendedprint.ui.button')|capitalize}</button> <a
		style="font-size: 80%;"
		href="{devblocks_url}c=config&a=extendedprint{/devblocks_url}" title = "{$translate->_('extendedprint.ui.cfg.extendedprintcfg')}"
		/>({$translate->_('extendedprint.ui.cfg.extendedprintcfgshort')}) </a>

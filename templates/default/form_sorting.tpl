<form action='?' method="get">
	<fieldset>
		<legend>Sorting preference</legend>
		<select name="sort_by">
[% FOREACH option IN SORTLIST -%]
			<option value="[% option.id %]"[% IF (option.id == PARAMETERS.SORT_ORDER) %] selected[% END %]>[% option.text %]</option>
[% END -%]
		</select>
		<input name="rev" type="checkbox" value="1"[% IF (PARAMETERS.SORT_REVERS == 1) %] checked[% END %]>Reverse order</select>
		<input type="submit" value="Submit">
	</fieldset>
</form>

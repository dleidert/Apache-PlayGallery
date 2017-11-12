<!DOCTYPE html>
<html>
<head>
	<title>[%- TITLE -%]</title>
	<!--{ $CSS }
	{ $ENCODING }
	{ $NAVIGATION } -->
</head>

<body>
	<header id="header">
		<h1>[%- TITLE -%]</h1>
	</header>

	<nav id="navigation">
[% INCLUDE form_sorting.tpl | indent('		') %] 
		[% MAIN %]
		<ul>
[% FOREACH file IN FILELIST -%]
			<li><a href="[% file | url %]">[% file %]</a></li>
[% END -%]
		</ul>
	</nav>

	<footer id="footer">
		<div id="copyright">
			<p>This page was created by <a href="[% HOMEPAGE %]">[% PACKAGE %]</a>.</p>
		</div>
	</footer>
</body>
</html>

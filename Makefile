publish-dry:
	flutter pub publish --dry-run

publish:
	flutter pub publish

gen-rewrite:
	fvm flutter pub run build_runner build --delete-conflicting-outputs

gen:
	fvm flutter pub run build_runner build

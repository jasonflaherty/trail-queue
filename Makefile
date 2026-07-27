.PHONY: bootstrap analyze test format dev docs

bootstrap:
	dart pub get
	dart pub global activate melos
	melos bootstrap

analyze:
	cd apps/client && flutter analyze
	cd packages/models && dart analyze
	cd packages/ui && flutter analyze
	cd packages/api && flutter analyze
	cd packages/map && flutter analyze

test:
	cd apps/client && flutter test
	cd packages/models && dart test || true

format:
	dart format apps packages

dev:
	cd apps/client && flutter run

supabase-start:
	supabase start

supabase-reset:
	supabase db reset

docs:
	@echo "Docs are in docs/ — open docs/getting-started.md"

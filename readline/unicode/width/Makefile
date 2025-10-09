all: tables.mbt
	moon build
.PHONY: all

info: pkg.generated.mbti
.PHONY: info

pkg.generated.mbti: tables.mbt
	moon info

tables.mbt:
	cd scripts && ./unicode.py
	moonfmt -w tables.mbt

clean:
	moon clean
	rm -rf .mooncakes/
.PHONY: clean

clean-all: clean
	rm tables.mbt
.PHONY: clean-all

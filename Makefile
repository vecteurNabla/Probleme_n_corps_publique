plot : tipe.cmx plot.cmx
	ocamlopt -o plot tipe.cmx plot.cmx

tipe.cmx : tipe.mli tipe.ml
	ocamlc -c tipe.mli
	ocamlopt -c tipe.ml

plot.cmx : plot.ml
	ocamlopt -c plot.ml

.PHONY : clean

clean :
	rm tipe_tests tipe.cmx tipe_tests.cmx tipe_rand_tests tipe_rand_tests.cmx

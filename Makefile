plot : tipe.cmo plot.cmo
	ocamlc -o plot tipe.cmo plot.cmo

tipe.cmo : tipe.mli tipe.ml
	ocamlc -c tipe.mli
	ocamlc -c tipe.ml

plot.cmo : plot.ml
	ocamlc -c plot.ml

.PHONY : clean

clean :
	rm tipe_tests tipe.cmo tipe_tests.cmo tipe_rand_tests tipe_rand_tests.cmo

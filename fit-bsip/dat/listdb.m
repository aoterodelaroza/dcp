#! /usr/bin/octave-cli -q

format long

wnci = 1;
wbde = 1;
wbderel = 0;
wdip = 100;
wene = 0.1;

## List of database files to use in DCP optimization
[listdb weightdb] = training_set(wnci,wbde,wbderel,wdip,wene);

fid1 = fopen("names.dat","w");
fid2 = fopen("w.dat","w");
for i = 1:length(listdb)
  fprintf(fid1,"%s\n",listdb{i});
  fprintf(fid2,"%.10f\n",weightdb(i));
endfor
fclose(fid1);
fclose(fid2);

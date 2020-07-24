#!/bin/bash

cd ~p2f-v/public_html

echo "#!/bin/bash" > wget_all_cvdp_files
echo " " >> wget_all_cvdp_files

ls public_html/PMIPVarDat*/*/*.nc | grep cvdp_data/ >> wget_all_cvdp_files
sed -i "s:public_html:wget http://www2.geog.ucl.ac.uk/~p2f-v/" wget_all_cvdp_files
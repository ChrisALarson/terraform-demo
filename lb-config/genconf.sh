for ip in $(sed "s/,/ /g")
do
  awk -v var="$ip" '/upstream demo_app_server/ { print; print "\tserver " var ":1337;"; next }1' nginx.conf > conf.tmp && mv conf.tmp nginx.conf
done <ips.txt
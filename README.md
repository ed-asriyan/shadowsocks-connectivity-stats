# Shadowsocks Connectivity Analysis
<i>The description, instructions and code quality may be poor - I wrote the code on a weekend while drinking beer. The goal was to gather statistics as quickly as possible. If you have any questions, please contact me (see my GitHub profile page for contact info).</i>

1. Setup multiple ShadowSocks proxies. Ideally they should be in different countries hosted by different vendors to have more wide stats. You can use this repo for that https://github.com/ed-asriyan/proxy-server
2. Create [SIP008](https://shadowsocks.org/doc/sip008.html) config and serve it by HTTPS somewhere
3. Ask your friends in censored country to
   1. Run the following command
      ```commandline
      docker build -f https://raw.githubusercontent.com/ed-asriyan/shadowsocks-connectivity-stats/master/1-collecting-data/Dockerfile -t ss-data-collector .
      ```
   2. Connect laptop to mobile ISP (usually mobile providers have better DPI)
   3. Run the following command
      ```commandline
      docker run --rm -e SS_CONF_URL=<SIP008 URL> ss-data-collector > stats.csv
      ```
      where `<SIP008 URL>` is URL you configured on the (2) step
   4. Send generated `stats.csv` to you
   5. If possible, connect to other ISPs and run 3.3-3.4 steps again to gather more info

   you can also run stats if you're in censored country `make SS_CONF_URL=<SIP008 URL> 1_collect_stats`
4. Concatinate all received CSVs into a single one.
5. Fill out the empty columns about each user:
   * user name
   * user's isp
6. Fill out the empty columns about each server:
   * hoster name
   * hoster location
5. Copy the table to [your-data/stats.csv](your-data/stats.csv)
6. Run `make 2_create_decition_tree`
7. Open and review new generated file `your-data/decision-table.svg`

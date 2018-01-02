
 Hare And Puma
 -------------

 hare_puma calculates the following PDEs for the distribution of hares and
 pumas on an island.
 
 dH/dt = rH - aHP + k(d2H/dx2 + d2H/dy2)
 dP/dt = bHP - mP + l(d2P/dx2 + d2P/dy2)
 
 Usage:
   hare_puma.sh config_file
 
 Config file:
  land_file=path/to/land.dat
  hare_file=path/to/hare.dat
  puma_file=path/to/puma.dat
 
  var_dt=0.1
  var_l=0.4
  var_m=0.4
  ...
 
 Variables not defined in the config file will be set to some sane default.
 Note that the land_file, hare_file and puma_file are currently required.
 
 Example files:
 
 land_file.dat:
 5 5
 0 1 0 0 1
 0 1 1 0 1
 1 1 1 1 1
 1 0 1 1 0
 1 1 1 0 0
 
 hare_file.dat:
 5 5
 0     0.34 0    0    3.5
 0     2.66 3.2  0    4.1
 1.23  1.12 2.3  2.67 3.5
 2.099 0    1.9  2.43 0
 2.53  2.2  1.89 0    0
 
 Note that the land files are 0 for water and 1 for land, and the hare and
 puma files define the density of hares or pumas in each tile location.
 The hare and puma tiles must be 0 where the land tiles are 0, and must
 be a positive number.
 
 There is no need to pad the hare or puma files so the columns line up, it
 just looks nice.


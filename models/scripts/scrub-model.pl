# change full paths to cmbuild and cmcalibrate to just 'cmbuild' and 'cmcalibrate'
while($line = <>) {
  chomp $line;
  if($line =~ /(^COM\s+\[\d+\]\s+)\S+cmbuild(.+)$/) {
    printf("%s%s%s\n", $1, "cmbuild", $2);
  }
  elsif($line =~ /(^COM\s+\[\d+\]\s+)\S+cmcalibrate(.+)$/) {
    printf("%s%s%s\n", $1, "cmcalibrate", $2);
  }
  else {
    print $line . "\n";
  }
}

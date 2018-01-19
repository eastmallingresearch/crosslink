# crosslink
Genetic mapping software for outbreeding species with additional features suitable for allo-polyploids.

For strawberry disease resistance QTL pipelines using this software see (https://github.com/harrisonlab/ananassa_qtl).

Available as a [VirtualBox](https://www.virtualbox.org) virtual machine image for cross-platform usage.

Get the image (xubuntu-crosslink.ova) from the latest [release](https://github.com/eastmallingresearch/crosslink/releases).

Run the docker image using: docker run -it rjvickerstaff/crosslink

See [docs/crosslink_manual.pdf](https://github.com/eastmallingresearch/crosslink/blob/master/docs/crosslink_manual.pdf) for further details.

Publication:
Crosslink: A fast, scriptable genetic mapper for out-crossing species
Robert J. Vickerstaff and Richard J. Harrison (in prep.)

## Note: bug fix
Eric van de Weg found a bug in the marker type correction code. This correction step changes the sex of markers which show strong linkage to many markers of the opposite parent (indicating they have been miscalled to begin with). For our octoploid strawberry data the most likely explanation is that the two clusters have been misidentified so that the heterozygous cluster was wrongly classified as homozygous and vice versa, therefore the parental and all progeny samples were miscalled. Therefore the correct way to fix the problem is to change lm -> nn and ll -> np and vice versa. However, previously crosslink was performing the correction as lm -> np and ll -> nn and vice versa, which introduces a phasing error in the corrected marker.

Be aware that if the cause of the incorrect sex of the marker was reciprocal miscalling of the two parental samples only with all progeny samples correctly called then the fixapplied by crosslink is now not correct. If you suspect this is the case for your data then you can get the names of the affected markers from the log file of crosslink_group and apply the appropriate correction yourself using a custom script.

The bug was fixed in the source code on 2017-04-05, so will appear in the first new release on or after this date.

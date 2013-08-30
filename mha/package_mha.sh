#!/bin/bash

MAT_ARGS='-nojvm -nodesktop -nosplash'

usage() {
printf "Usage: %s [ant_name_prefix] [cyc_name_prefix] [dest]\n" "$(basename $0)"
printf "\t ant_name_prefix: anticyclonic data name without _fX.mat extension\n"
printf "\t cyc_name_prefix: cyclonic data name without _fX.mat extension\n"
printf "\t            dest: destination file (should NOT end in .tar.gz)\n"
}


if (( $# != 3 )); then
	usage
	exit 1
fi

ant_pre=$1
cyc_pre=$2
dest=$3

if [[ ! -f "$dest.tar.gz" ]]; then
	printf "Building Complete Dataset Tarball: $dest.tar.gz..."
	tar czf "$dest.tar.gz" "$ant_pre"_f*.mat "$cyc_pre"_f*.mat
	if [[ $? -ne 0 ]]; then
		printf "FAIL\n"
		exit 2
	fi
	printf "DONE\n"
fi

if [[ ! -f "${ant_pre}_simple.mat" ]]; then
	printf "Building Anticyc Simple Dataset: ${ant_pre}_simple.mat..."
	matlab $MAT_ARGS -r "data = load_mha('$ant_pre'); s_tracks = export_tracks_simple(data.tracks); save('${ant_pre}_simple', 's_tracks'); exit();" &>/dev/null
	if [[ ! -f "${ant_pre}_simple.mat" ]]; then
		printf "FAIL\n"
		exit 3
	fi
	printf "DONE\n"
fi

if [[ ! -f "${cyc_pre}_simple.mat" ]]; then
	printf "Building Cyclonic Simple Dataset: ${cyc_pre}_simple.mat..."
	matlab $MAT_ARGS -r "data = load_mha('$cyc_pre'); s_tracks = export_tracks_simple(data.tracks); save('${cyc_pre}_simple', 's_tracks'); exit();" &>/dev/null
	if [[ ! -f "${cyc_pre}_simple.mat" ]]; then
		printf "FAIL\n"
		exit 3
	fi
	printf "DONE\n"
fi

if [[ ! -f "${dest}_simple.tar.gz" ]]; then
	printf "Building Simple Dataset Tarball: ${dest}_simple.tar.gz..."
	tar czf "${dest}_simple.tar.gz" "$ant_pre"_simple.mat "$cyc_pre"_simple.mat
	if [[ $? -ne 0 ]]; then
		printf "FAIL\n"
		exit 2
	fi
	printf "DONE\n"
fi

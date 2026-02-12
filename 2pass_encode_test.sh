#!/bin/bash
set -e
set -x

SOURCE="source"
ENCODED="encoded"
DONE="done"

mkdir -p "$SOURCE" "$ENCODED" "$DONE"

res=("3840:-2" "2560:-2" "1920:-2" "1280:-2" "854:-2" "480:-2")
bitrate=("26000k" "15000k" "7000k" "4000k" "2000k" "1000k")

for INPUT in "$SOURCE"/*; do
    [ -e "$INPUT" ] || continue
    BASENAME=$(basename "$INPUT")
    NAME="${BASENAME%.*}"

    OUTDIR="$ENCODED/$NAME"
    echo "Encoding $BASENAME"

    mkdir -p "$OUTDIR"
    for i in ${!res[@]}; do
	    BUFSIZE=$(( 2 * ${bitrate[i]%k} ))k
        ffmpeg -y -i "$INPUT" -vf "scale=${res[i]}" -c:v libx264 \
            -b:v ${bitrate[i]} -minrate:v ${bitrate[i]} \
            -maxrate:v ${bitrate[i]} -bufsize:v ${BUFSIZE} \
            -g 120 -keyint_min 120 \
            -force_key_frames "expr:gte(t,n_forced*4)" \
	    -pass 1 -passlogfile "$OUTDIR/res_$i.log" -an -f mp4 /dev/null 
	   
       	if [ $i -eq 0 ]; then
            ffmpeg -y -i "$INPUT" -vf "scale=${res[i]}" -c:v libx264 \
                -b:v ${bitrate[i]} -minrate:v ${bitrate[i]} \
                -maxrate:v ${bitrate[i]} -bufsize:v ${BUFSIZE} \
                -g 120 -keyint_min 120 \
                -force_key_frames "expr:gte(t,n_forced*4)" \
                -pass 2 -passlogfile "$OUTDIR/res_$i.log" \
		        -c:a aac -b:a 128k -ac 2 "$OUTDIR/res_$i.mp4"
        else
            ffmpeg -y -i "$INPUT" -vf "scale=${res[i]}" -c:v libx264 \
                -b:v ${bitrate[i]} -minrate:v ${bitrate[i]} \
                -maxrate:v ${bitrate[i]} -bufsize:v ${BUFSIZE} \
                -g 120 -keyint_min 120 \
                -force_key_frames "expr:gte(t,n_forced*4)" \
                -pass 2 -passlogfile "$OUTDIR/pass_$i.log" \
		        -an "$OUTDIR/res_$i.mp4"
        fi
        rm -f "$OUTDIR/res_$i.log"*
    done

    DASH_CMD="ffmpeg"
    for i in ${!res[@]}; do
        DASH_CMD+=" -i $OUTDIR/res_$i.mp4"
    done

    MAP_ARGS=""
    for i in ${!res[@]}; do
        MAP_ARGS+=" -map $i:v "
    done
    MAP_ARGS+=" -map 0:a"

    $DASH_CMD $MAP_ARGS -c copy \
        -f dash -seg_duration 5 -use_timeline 1 -use_template 1 \
        -init_seg_name "init-$NAME-\$RepresentationID\$.mp4" \
        -media_seg_name "chunk-$NAME-\$RepresentationID\$-\$Number%05d\$.m4s" \
        -adaptation_sets "id=0,streams=v id=1,streams=a" \
        "$OUTDIR/$NAME.mpd"

    echo "Done Encoding $BASENAME"
    mv "$INPUT" "$DONE/"
done

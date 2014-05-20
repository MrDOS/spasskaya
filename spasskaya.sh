#! /bin/sh

# Generate playtime stats from Minecraft player stat files.

STATS=/home/seecraft/minecraft-server/world/stats/*.json

# Given JSON stat files as arguments, determine the playtime in ticks and
# username of the player.
playtimes ()
{
    for player in $@
    do
        uuid=`echo "$player" | sed -e 's/.*\///' | sed -e 's/.json$//'`
        if ! echo "$uuid" | grep -qP '[a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12}'
        then
            continue
        fi
        bare_uuid=`echo "$uuid" | sed -e 's/-//g'`
        name=`curl -s https://sessionserver.mojang.com/session/minecraft/profile/"$bare_uuid" \
    | grep -oP '.*\[' | grep -oP -m 1 '"name":".+?"' | sed -e 's/"name":"\(.*\)"/\1/'`
        playtime=`grep -oP '"stat.playOneMinute":\d+' "$player" | sed -e 's/.*://'`

        echo "$playtime $name"
    done
}

# Given JSON stat files as arguments, format the playtime in ticks into H:mm:ss.
format_playtimes ()
{
    playtimes $@ | sort -nr | while read player
    do
        playtime=`echo "$player" | cut -d ' ' -f 1`
        name=`echo "$player" | cut -d ' ' -f 2`

        total_seconds=`expr $playtime / 20`
        hours=`expr $total_seconds / 3600`
        minutes=`expr \( $total_seconds % \( $hours \* 60 \) \) / 60`
        seconds=`expr $total_seconds % 60`

        printf "%d:%02d:%02d %s\n" "$hours" "$minutes" "$seconds" "$name"
    done
}

# Given a series of column names as arguments and rows as stdin, generate an
# HTML table.
tablize ()
{
    echo "<table><thead><tr>"
    for column_name in $@
    do
        echo "<th>$column_name</th>"
    done
    echo "</tr></thead><tbody>"

    while read row
    do
        echo "<tr>"
        for column in $row
        do
            echo "<td>$column</td>"
        done
        echo "</tr>"
    done

    echo "</tbody></table>"
}

format_playtimes $STATS | tablize "Playtime" "Name"

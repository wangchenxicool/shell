#!/bin/bash
# 用case语句设计一个简单菜单

function draw_menu()
{
    clear # 清屏.
    echo "          --main menu-- "
    echo "       -------- ---------";
    echo "Choose one of the following options:";
    echo
    echo "[E]-vans, Roland";
    echo "[J]-ones, Mildred";
    echo "[S]-mith, Julie";
    echo "[Z]-ane, Morris";
    echo "[Q]-exit!";
    echo
    echo "Which your Selection?";
}

refurbish_flg=1
while true; do
    if ((refurbish_flg)); then
        draw_menu;
        refurbish_flg=0;
    fi
    read -s -n1 Keypress;
    case "$Keypress" in
       "E" | "e" )
            echo
            echo "Roland Evans";
            echo "4321 Floppy Dr.";
            echo "Hardscrabble, CO 80753";
            echo "(303) 734-9874";
            echo "(303) 734-9892 fax";
            echo "revans@zzy.net";
            echo "Business partner & old friend";
            echo -e "\a";
            refurbish_flg=1;
            read -s -n1;;

        "J" | "j" )
            echo
            echo "Mildred Jones";
            echo "249 E. 7th St., Apt. 19";
            echo "New York, NY 10009";
            echo "(212) 533-2814";
            echo "(212) 533-9972 fax";
            echo "milliej@loisaida.com";
            echo "Ex-girlfriend";
            echo "Birthday: Feb. 11";
            echo -e "\a";
            refurbish_flg=1;
            read -s -n1;;

        "S" | "s" )
            echo
            echo "Mildred Jones";
            echo "249 E. 7th St., Apt. 19";
            echo "New York, NY 10009";
            echo "(212) 533-2814";
            echo "(212) 533-9972 fax";
            echo "milliej@loisaida.com";
            echo "Ex-girlfriend";
            echo "Birthday: Feb. 11";
            echo -e "\a";
            refurbish_flg=1;
            read -s -n1;;

        "Z" | "z" )
            echo
            echo "Mildred Jones";
            echo "249 E. 7th St., Apt. 19";
            echo "New York, NY 10009";
            echo "(212) 533-2814";
            echo "(212) 533-9972 fax";
            echo "milliej@loisaida.com";
            echo "Ex-girlfriend";
            echo "Birthday: Feb. 11";
            echo -e "\a";
            refurbish_flg=1;
            read -s -n1;;

        "q" | "Q"   )
            echo -e "\a";
            break;;
        *   )
    esac
done #end while

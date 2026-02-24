#!/bin/bash
set -eux

# customize lightdm
sed 's@background = .*@background = /usr/share/backgrounds/kali-16x9/kali-hack.jpg@' -i /etc/lightdm/lightdm-gtk-greeter.conf
sed 's@theme-name = Kali-Light@theme-name = Kali-Dark@' -i /etc/lightdm/lightdm-gtk-greeter.conf
echo 'hide-user-image = true' >>/etc/lightdm/lightdm-gtk-greeter.conf

# autofill vagrant user on lightdm
sed 's/#\?greeter-hide-users=.*/greeter-hide-users=false/' -i /etc/lightdm/lightdm.conf

# set user dirs
cat <<EOF >/etc/xdg/user-dirs.defaults
DESKTOP=desk
DOWNLOAD=downloads
TEMPLATES=
PUBLICSHARE=
DOCUMENTS=
MUSIC=
PICTURES=
VIDEOS=
EOF

# set desk icons on desktop with some pins
cat <<EOF >/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="brightness" type="empty"/>
        <property name="color1" type="empty"/>
        <property name="color2" type="empty"/>
        <property name="color-style" type="empty"/>
        <property name="image-path" type="empty"/>
        <property name="image-show" type="empty"/>
        <property name="last-image" type="empty"/>
        <property name="last-single-image" type="empty"/>
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="1"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/images/desktop-base/default"/>
        </property>
        <property name="workspace1" type="empty">
          <property name="color-style" type="int" value="1"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/images/desktop-base/default"/>
        </property>
        <property name="workspace2" type="empty">
          <property name="color-style" type="int" value="1"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/images/desktop-base/default"/>
        </property>
        <property name="workspace3" type="empty">
          <property name="color-style" type="int" value="1"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/images/desktop-base/default"/>
        </property>
      </property>
      <property name="monitor1" type="empty">
        <property name="brightness" type="empty"/>
        <property name="color1" type="empty"/>
        <property name="color2" type="empty"/>
        <property name="color-style" type="empty"/>
        <property name="image-path" type="empty"/>
        <property name="image-show" type="empty"/>
        <property name="last-image" type="empty"/>
        <property name="last-single-image" type="empty"/>
      </property>
      <property name="monitorVirtual-1" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="1"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/backgrounds/kali-16x9/kali-hack.jpg"/>
        </property>
      </property>
    </property>
  </property>
  <property name="desktop-icons" type="empty">
    <property name="style" type="int" value="2"/>
    <property name="file-icons" type="empty">
      <property name="show-trash" type="bool" value="false"/>
      <property name="show-filesystem" type="bool" value="false"/>
      <property name="show-removable" type="bool" value="false"/>
      <property name="show-home" type="bool" value="false"/>
    </property>
    <property name="show-hidden-files" type="bool" value="false"/>
    <property name="primary" type="bool" value="false"/>
    <property name="gravity" type="int" value="0"/>
    <property name="tooltip-size" type="double" value="52"/>
    <property name="show-thumbnails" type="bool" value="false"/>
  </property>
  <property name="last" type="empty">
    <property name="window-width" type="int" value="691"/>
    <property name="window-height" type="int" value="649"/>
  </property>
</channel>
EOF

# set only top panel
cat <<EOF >/etc/xdg/xfce4/panel/default.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="34"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="8"/>
        <value type="int" value="11"/>
        <value type="int" value="12"/>
        <value type="int" value="9"/>
        <value type="int" value="10"/>
        <value type="int" value="14"/>
        <value type="int" value="15"/>
        <value type="int" value="16"/>
        <value type="int" value="19"/>
        <value type="int" value="20"/>
      </property>
      <property name="background-style" type="uint" value="0"/>
    </property>
    <property name="dark-mode" type="bool" value="false"/>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="whiskermenu">
      <property name="recent" type="array">
        <value type="string" value="kali-amass.desktop"/>
        <value type="string" value="kali-burpsuite.desktop"/>
        <value type="string" value="xfce-settings-manager.desktop"/>
      </property>
      <property name="view-mode" type="int" value="2"/>
    </property>
    <property name="plugin-2" type="string" value="separator">
      <property name="style" type="uint" value="0"/>
      <property name="expand" type="bool" value="false"/>
    </property>
    <property name="plugin-3" type="string" value="showdesktop"/>
    <property name="plugin-4" type="string" value="directorymenu">
      <property name="icon-name" type="string" value="system-file-manager"/>
      <property name="base-directory" type="string" value="/home/vagrant"/>
    </property>
    <property name="plugin-8" type="string" value="separator">
      <property name="style" type="uint" value="2"/>
      <property name="expand" type="bool" value="false"/>
    </property>
    <property name="plugin-9" type="string" value="pager">
      <property name="miniature-view" type="bool" value="true"/>
      <property name="rows" type="uint" value="1"/>
    </property>
    <property name="plugin-900" type="string" value="pager">
      <property name="miniature-view" type="bool" value="true"/>
      <property name="rows" type="uint" value="2"/>
    </property>
    <property name="plugin-10" type="string" value="separator">
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-11" type="string" value="tasklist">
      <property name="show-handle" type="bool" value="false"/>
      <property name="show-labels" type="bool" value="true"/>
      <property name="middle-click" type="uint" value="1"/>
      <property name="grouping" type="bool" value="false"/>
      <property name="flat-buttons" type="bool" value="false"/>
      <property name="show-tooltips" type="bool" value="true"/>
      <property name="show-wireframes" type="bool" value="false"/>
    </property>
    <property name="plugin-12" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-14" type="string" value="systray">
      <property name="size-max" type="uint" value="22"/>
      <property name="square-icons" type="bool" value="true"/>
      <property name="symbolic-icons" type="bool" value="false"/>
      <property name="known-legacy-items" type="array">
        <value type="string" value="networkmanager applet"/>
      </property>
    </property>
    <property name="plugin-15" type="string" value="genmon"/>
    <property name="plugin-16" type="string" value="pulseaudio">
      <property name="enable-keyboard-shortcuts" type="bool" value="true"/>
      <property name="known-players" type="string" value="Chromium"/>
    </property>
    <property name="plugin-19" type="string" value="clock">
      <property name="digital-layout" type="uint" value="3"/>
      <property name="digital-time-format" type="string" value="%_H:%M"/>
      <property name="digital-time-font" type="string" value="Cantarell 11"/>
    </property>
    <property name="plugin-20" type="string" value="separator">
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-2200" type="string" value="actions">
      <property name="appearance" type="uint" value="0"/>
      <property name="items" type="array">
        <value type="string" value="-lock-screen"/>
        <value type="string" value="-switch-user"/>
        <value type="string" value="-separator"/>
        <value type="string" value="-suspend"/>
        <value type="string" value="-hibernate"/>
        <value type="string" value="-hybrid-sleep"/>
        <value type="string" value="-separator"/>
        <value type="string" value="-shutdown"/>
        <value type="string" value="-restart"/>
        <value type="string" value="-separator"/>
        <value type="string" value="+logout"/>
        <value type="string" value="-logout-dialog"/>
      </property>
    </property>
  </property>
</channel>
EOF

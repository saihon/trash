## trash

<br/>

This command trashes files and directories or empties the Trash.

<br/>

Tested on Ubuntu 22.04

The path of directory to be deleted is `/home/$(logname)/.local/shere/Trash`.
When deleting, not only "files" directory also everything in the Trash including "expunged" and "info".

<br/>
<br/>

## Installation

<br/>

* Installed GNU make.
  ```
  git clone https://github.com/saihon/trash.git
  make
  sudo make install
  ```
  NOTE: Run make will generate a file named "tt". if change it, rewrite NAME in Makefile or install manually like bellow.

<br/>

* Manually (download & build & install)
  ```
  wget https://raw.githubusercontent.com/saihon/trash/master/trash.sh
  cp trash.sh tt
  chmod 755 tt
  sudo mv tt /usr/local/bin/
  ```

<br/>
<br/>

## Usage

<br/>

* Moves to Trash.
  ```
  $ tt LICENSE Makefile README.md trash.sh
  ```

<br/>

* Show in Trash formatted long. internally `ls -l`
  ```
  $ tt -l
  ```

<br/>

* Show in Trash including hidden. internally `ls -A`
  ```
  $ tt -a
  ```

<br/>

* Empties in Trash.
  ```
  $ tt -e
  ```

<br/>

* Confirm before empties.
  ```
  $ tt -c
  ```

<br/>
<br/>

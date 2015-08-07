---
published: false
---

# Software Defined Radio tools OSX Install

This will walk you through getting gnuradio and device-specific libraries to work on OSX. It is really just an adaptation of the awesome collection of [Homebrew](https://github.com/mxcl/homebrew) recipes from [Titanous](https://github.com/titanous/homebrew-gnuradio) for getting GNU Radio running on OSX.

## Installation

- Install the prerequisite python packages

  ```sh
  pip install numpy==1.5.1 Cheetah lxml
  pip install https://github.com/scipy/scipy/archive/v0.12.0.tar.gz
  export PKG_CONFIG_PATH="/usr/X11/lib/pkgconfig" 
  pip install https://downloads.sourceforge.net/project/matplotlib/matplotlib/matplotlib-1.2.1/matplotlib-1.2.1.tar.gz
  ```

- Install `wxmac` 2.9 with python bindings

  ```sh
  brew install wxmac --python
  ```

- Install gnuradio 

  ```sh
  brew tap cole-christensen/rfbrew
  brew install gnuradio --with-qt
  ```
- Install HackRF Libraries

  ```sh
  brew install hackrf
  ```

- Create the `~/.gnuradio/config.conf` config file for custom block support and add this into it

  ```ini
  [grc]
  local_blocks_path=/usr/local/share/gnuradio/grc/blocks
  ```

- Install BladeRF, HackRF, and RTL-SDR related blocks

  ```sh
  brew install bladerf rtlsdr gr-osmosdr gr-baz
  ```
- If you want a graphic interface to play with your HackRF, GQRX is great
  To install it:
  
  ```sh
  brew install --HEAD gqrx
  ```
  
  To run:
  
  ```sh
  gqrx
  ```
  
  And then configure it to use the HackRF. Probably best to start the sample rate at 1000000 until you know how much your system can handle.
  
**Congratulations!!**

Everything should now be working. It is time to give it a try! Below are some of the programs you can try

```sh
gnuradio-companion
osmocom_fft -a hackrf
```

##Troubleshooting

- **Matplotlib**

  If you get the following type of errors installing matplotlib:

  > error: expected identifier or '(' before '^' token
    
  Try the following:
      
  ```sh
  export CC=clang
  export CXX=clang++
  export LDFLAGS="-L/usr/X11/lib"
  export CFLAGS="-I/usr/X11/include -I/usr/X11/include/freetype2"
  ```
      
  From [Stackoverflow](http://stackoverflow.com/questions/12363557/matplotlib-install-failure-on-mac-osx-10-8-mountain-lion/15098059#15098059) via [@savant42](https://twitter.com/savant42)

- **Uninstall Homebrew**
  If you think you have some cruftiness with Homebrew, this Gist will completely uninstall Homebrew and any libraries it may have installed. Of course if you are using Homebrew for other things you could make a mess of your life. 
  
  This [Gist](https://gist.github.com/mxcl/1173223) is from the [Homebrew FAQ](https://github.com/mxcl/homebrew/wiki/FAQ)
  
  Then finish the clean-up with these steps
  
  ```sh
  rm -rf /usr/local/Cellar /usr/local/.git && brew cleanup
  rm -rf /Library/Caches/Homebrew
  rm -rf /usr/local/lib/python2.7/site-packages
  ```


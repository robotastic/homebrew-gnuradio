require 'formula'

class GrFosphor < Formula
  homepage 'http://sdr.osmocom.org/trac/wiki/fosphor'
  url 'git://git.osmocom.org/gr-fosphor.git', :commit => '985c78ffa7ecfc0d4b5b43d2541e68a9e6d94576'
  revision '1'

  depends_on 'cmake' => :build
  depends_on 'gnuradio'

  def install
    mkdir 'build' do
      system 'cmake', '..', '-DPYTHON_LIBRARY=/usr/local/Frameworks/Python.framework/Versions/2.7/Python ', *std_cmake_args
      system 'make'
      system 'make install'
    end
  end
end

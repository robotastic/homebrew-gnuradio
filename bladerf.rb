require 'formula'

class Bladerf < Formula
  homepage 'http://wiki.spench.net/wiki/Gr-baz'
  url 'https://github.com/Nuand/bladeRF.git', :tag => '2015.02'
  revision '2'

  depends_on 'cmake' => :build

  def install
    mkdir 'build' do
      system 'cmake', '..', '-DTAGGED_RELEASE=On -DENABLE_FX3_BUILD=Off -DENABLE_HOST_BUILD=On', *std_cmake_args
      system 'make'
      system 'make install'
    end
  end
end

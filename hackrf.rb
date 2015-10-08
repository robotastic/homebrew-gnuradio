class Hackrf < Formula
  homepage 'https://github.com/mossmann/hackrf/wiki'
  head 'https://github.com/mossmann/hackrf.git'

  depends_on 'cmake' => :build
  depends_on 'libusb'

  def install
    cd "host" do
      system "cmake", ".", *std_cmake_args
      system "make", "install"
    end
  end
end

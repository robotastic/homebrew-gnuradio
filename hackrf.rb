require 'formula'

# Documentation: https://github.com/mxcl/homebrew/wiki/Formula-Cookbook
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!

class Hackrf < Formula
  homepage 'https://github.com/mossmann/hackrf/wiki'
  head 'https://github.com/mossmann/hackrf.git'

  depends_on 'cmake' => :build
  depends_on 'pkg-config' => :build
  depends_on 'libusb'

  def install
    # ENV.j1  # if your formula's build system can't parallelize

    #system "./configure", "--disable-debug", "--disable-dependency-tracking",
    #                      "--prefix=#{prefix}"
    cd "host" do
      system "cmake", ".", *std_cmake_args
      system "make", "install" # if this fails, try separate make/make install steps
    end
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test hackrf`.
    system "false"
  end
end

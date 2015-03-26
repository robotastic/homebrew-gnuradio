require 'formula'

class Gnuradio < Formula
  homepage 'http://gnuradio.org'
  url  'http://gnuradio.org/releases/gnuradio/gnuradio-3.6.5.1.tar.gz'
  sha1 '8d3846dc1d00c60b74f06c0bb8f40d57ee257b5a'
  head 'http://gnuradio.org/git/gnuradio.git'

  depends_on 'cmake' => :build
  depends_on 'Cheetah' => :python
  depends_on 'lxml' => :python
  depends_on 'numpy' => :python
  depends_on 'scipy' => :python
  depends_on 'matplotlib' => :python
  depends_on 'python'
  depends_on 'boost'
  depends_on 'cppunit'
  depends_on 'gsl'
  depends_on 'fftw'
  depends_on 'swig'
  depends_on 'pygtk'
  depends_on 'sdl'
  depends_on 'libusb'
  depends_on 'orc'
  depends_on 'pyqt' if ARGV.include?('--with-qt')
  depends_on 'pyqwt' if ARGV.include?('--with-qt')
  depends_on 'doxygen' if ARGV.include?('--with-docs')

  fails_with :clang do
    build 421
    cause "Fails to compile .S files."
  end

  fails_with :llvm

  def options
    [
      ['--with-qt', 'Build gr-qtgui.'],
      ['--with-docs', 'Build docs.']
    ]
  end

  def patches
    DATA
  end

  def install
    mkdir 'build' do
      args = ["-DCMAKE_PREFIX_PATH=#{prefix}", "-DQWT_INCLUDE_DIRS=#{HOMEBREW_PREFIX}/lib/qwt.framework/Headers"] + std_cmake_args
      args << '-DENABLE_GR_QTGUI=OFF' unless ARGV.include?('--with-qt')
      args << '-DENABLE_DOXYGEN=OFF' unless ARGV.include?('--with-docs')

      # From opencv.rb
      python_prefix = `python-config --prefix`.strip
      # Python is actually a library. The libpythonX.Y.dylib points to this lib, too.
      if File.exist? "#{python_prefix}/Python"
        # Python was compiled with --framework:
        args << "-DPYTHON_LIBRARY='#{python_prefix}/Python'"
        if !MacOS::CLT.installed? and python_prefix.start_with? '/System/Library'
          # For Xcode-only systems, the headers of system's python are inside of Xcode
          args << "-DPYTHON_INCLUDE_DIR='#{MacOS.sdk_path}/System/Library/Frameworks/Python.framework/Versions/2.7/Headers'"
        else
          args << "-DPYTHON_INCLUDE_DIR='#{python_prefix}/Headers'"
        end
      else
        python_lib = "#{python_prefix}/lib/lib#{which_python}"
        if File.exists? "#{python_lib}.a"
          args << "-DPYTHON_LIBRARY='#{python_lib}.a'"
        else
          args << "-DPYTHON_LIBRARY='#{python_lib}.dylib'"
        end
        args << "-DPYTHON_INCLUDE_DIR='#{python_prefix}/include/#{which_python}'"
      end
      args << "-DPYTHON_PACKAGES_PATH='#{lib}/#{which_python}/site-packages'"

      system 'cmake', '..', *args
      system 'make'
      system 'make install'
    end
  end

  def python_path
    python = Formula.factory('python')
    kegs = python.rack.children.reject { |p| p.basename.to_s == '.DS_Store' }
    kegs.find { |p| Keg.new(p).linked? } || kegs.last
  end

  def caveats
    <<-EOS.undent
    If you want to use custom blocks, create this file:

    ~/.gnuradio/config.conf
      [grc]
      local_blocks_path=/usr/local/share/gnuradio/grc/blocks
    EOS
  end

  def which_python
    "python" + `python -c 'import sys;print(sys.version[:3])'`.strip
  end
end

__END__
diff --git a/grc/CMakeLists.txt b/grc/CMakeLists.txt
index f54aa4f..db0ce3c 100644
--- a/grc/CMakeLists.txt
+++ b/grc/CMakeLists.txt
@@ -25,7 +25,7 @@ include(GrPython)
 GR_PYTHON_CHECK_MODULE("python >= 2.5"     sys          "sys.version.split()[0] >= '2.5'"           PYTHON_MIN_VER_FOUND)
 GR_PYTHON_CHECK_MODULE("Cheetah >= 2.0.0"  Cheetah      "Cheetah.Version >= '2.0.0'"                CHEETAH_FOUND)
 GR_PYTHON_CHECK_MODULE("lxml >= 1.3.6"     lxml.etree   "lxml.etree.LXML_VERSION >= (1, 3, 6, 0)"   LXML_FOUND)
-GR_PYTHON_CHECK_MODULE("pygtk >= 2.10.0"   gtk          "gtk.pygtk_version >= (2, 10, 0)"           PYGTK_FOUND)
+GR_PYTHON_CHECK_MODULE("pygtk >= 2.10.0"   pygtk        True                                        PYGTK_FOUND)
 GR_PYTHON_CHECK_MODULE("numpy"             numpy        True                                        NUMPY_FOUND)

 ########################################################################

diff --git a/gr-qtgui/lib/spectrumdisplayform.ui b/gr-qtgui/lib/spectrumdisplayform.ui
index 049d4ff..43e6857 100644
--- a/gr-qtgui/lib/spectrumdisplayform.ui
+++ b/gr-qtgui/lib/spectrumdisplayform.ui
@@ -330,9 +330,6 @@
          <property name="focusPolicy">
           <enum>Qt::WheelFocus</enum>
          </property>
-         <property name="valid">
-          <bool>true</bool>
-         </property>
          <property name="totalAngle">
           <double>200.000000000000000</double>
          </property>
@@ -384,9 +381,6 @@
            <height>0</height>
           </size>
          </property>
-         <property name="valid">
-          <bool>true</bool>
-         </property>
          <property name="totalAngle">
           <double>200.000000000000000</double>
          </property>
@@ -518,7 +512,6 @@
   </layout>
  </widget>
  <layoutdefault spacing="6" margin="11"/>
- <pixmapfunction>qPixmapFromMimeSource</pixmapfunction>
  <customwidgets>
   <customwidget>
    <class>QwtWheel</class>

diff --git a/gnuradio-core/src/lib/io/ppio_ppdev.h b/gnuradio-core/src/lib/io/ppio_ppdev.h
index 1f86d7e..9b2c4f1 100644
--- a/gnuradio-core/src/lib/io/ppio_ppdev.h
+++ b/gnuradio-core/src/lib/io/ppio_ppdev.h
@@ -35,7 +35,7 @@ typedef boost::shared_ptr<ppio_ppdev> ppio_ppdev_sptr;
  */
 
 class GR_CORE_API ppio_ppdev : public ppio {
-  friend GR_CORE_API ppio_ppdev_sptr make_ppio_ppdev (int which = 0);
+  friend GR_CORE_API ppio_ppdev_sptr make_ppio_ppdev (int which);
   ppio_ppdev (int which = 0);
 
  public:
diff --git a/gr-qtgui/include/qtgui_util.h b/gr-qtgui/include/qtgui_util.h
index 2deaddb..7ba9b64 100644
--- a/gr-qtgui/include/qtgui_util.h
+++ b/gr-qtgui/include/qtgui_util.h
@@ -27,6 +27,7 @@
 #include <gr_qtgui_api.h>
 #include <qwt_plot_picker.h>
 #include <qwt_picker_machine.h>
+#include <qwt_plot_canvas.h>
 
 
 class GR_QTGUI_API QwtDblClickPlotPicker: public QwtPlotPicker
diff --git a/gr-qtgui/lib/ConstellationDisplayPlot.cc b/gr-qtgui/lib/ConstellationDisplayPlot.cc
index 7a595fe..89eb6d1 100644
--- a/gr-qtgui/lib/ConstellationDisplayPlot.cc
+++ b/gr-qtgui/lib/ConstellationDisplayPlot.cc
@@ -107,7 +107,7 @@ ConstellationDisplayPlot::ConstellationDisplayPlot(QWidget* parent)
   memset(_realDataPoints, 0x0, _numPoints*sizeof(double));
   memset(_imagDataPoints, 0x0, _numPoints*sizeof(double));
 
-  _zoomer = new ConstellationDisplayZoomer(canvas());
+  _zoomer = new ConstellationDisplayZoomer(dynamic_cast<QwtPlotCanvas *>(canvas()));
 
 #if QWT_VERSION < 0x060000
   _zoomer->setSelectionFlags(QwtPicker::RectSelection | QwtPicker::DragSelection);
@@ -134,7 +134,7 @@ ConstellationDisplayPlot::ConstellationDisplayPlot(QWidget* parent)
   _zoomer->setTrackerPen(c);
 
   // emit the position of clicks on widget
-  _picker = new QwtDblClickPlotPicker(canvas());
+  _picker = new QwtDblClickPlotPicker(dynamic_cast<QwtPlotCanvas *>(canvas()));
 
 #if QWT_VERSION < 0x060000
   connect(_picker, SIGNAL(selected(const QwtDoublePoint &)),
diff --git a/gr-qtgui/lib/FrequencyDisplayPlot.cc b/gr-qtgui/lib/FrequencyDisplayPlot.cc
index b74d460..d84fcdb 100644
--- a/gr-qtgui/lib/FrequencyDisplayPlot.cc
+++ b/gr-qtgui/lib/FrequencyDisplayPlot.cc
@@ -249,7 +249,7 @@ FrequencyDisplayPlot::FrequencyDisplayPlot(QWidget* parent)
   replot();
 
   // emit the position of clicks on widget
-  _picker = new QwtDblClickPlotPicker(canvas());
+  _picker = new QwtDblClickPlotPicker(dynamic_cast<QwtPlotCanvas*>(canvas()));
 
 #if QWT_VERSION < 0x060000
   connect(_picker, SIGNAL(selected(const QwtDoublePoint &)),
@@ -263,7 +263,7 @@ FrequencyDisplayPlot::FrequencyDisplayPlot(QWidget* parent)
   _magnifier = new QwtPlotMagnifier(canvas());
   _magnifier->setAxisEnabled(QwtPlot::xBottom, false);
 
-  _zoomer = new FreqDisplayZoomer(canvas(), 0);
+  _zoomer = new FreqDisplayZoomer(dynamic_cast<QwtPlotCanvas*>(canvas()), 0);
 
 #if QWT_VERSION < 0x060000
   _zoomer->setSelectionFlags(QwtPicker::RectSelection | QwtPicker::DragSelection);
diff --git a/gr-qtgui/lib/TimeDomainDisplayPlot.cc b/gr-qtgui/lib/TimeDomainDisplayPlot.cc
index 84b09af..31073de 100644
--- a/gr-qtgui/lib/TimeDomainDisplayPlot.cc
+++ b/gr-qtgui/lib/TimeDomainDisplayPlot.cc
@@ -102,7 +102,7 @@ TimeDomainDisplayPlot::TimeDomainDisplayPlot(int nplots, QWidget* parent)
   _xAxisPoints = new double[_numPoints];
   memset(_xAxisPoints, 0x0, _numPoints*sizeof(double));
 
-  _zoomer = new TimeDomainDisplayZoomer(canvas(), 0);
+  _zoomer = new TimeDomainDisplayZoomer(dynamic_cast<QwtPlotCanvas*>(canvas()), 0);
 
 #if QWT_VERSION < 0x060000
   _zoomer->setSelectionFlags(QwtPicker::RectSelection | QwtPicker::DragSelection);
@@ -169,7 +169,7 @@ TimeDomainDisplayPlot::TimeDomainDisplayPlot(int nplots, QWidget* parent)
   _panner->setMouseButton(Qt::MidButton);
 
   // emit the position of clicks on widget
-  _picker = new QwtDblClickPlotPicker(canvas());
+  _picker = new QwtDblClickPlotPicker(dynamic_cast<QwtPlotCanvas*>(canvas()));
 
 #if QWT_VERSION < 0x060000
   connect(_picker, SIGNAL(selected(const QwtDoublePoint &)),
@@ -195,7 +195,7 @@ TimeDomainDisplayPlot::TimeDomainDisplayPlot(int nplots, QWidget* parent)
   _zoomer->setTrackerPen(c);
 
   QwtLegend* legendDisplay = new QwtLegend(this);
-  legendDisplay->setItemMode(QwtLegend::CheckableItem);
+  legendDisplay->setDefaultItemMode(QwtLegendData::Checkable);
   insertLegend(legendDisplay);
 
   connect(this, SIGNAL( legendChecked(QwtPlotItem *, bool ) ),
diff --git a/gr-qtgui/lib/WaterfallDisplayPlot.cc b/gr-qtgui/lib/WaterfallDisplayPlot.cc
index 63eb57f..e34b6fa 100644
--- a/gr-qtgui/lib/WaterfallDisplayPlot.cc
+++ b/gr-qtgui/lib/WaterfallDisplayPlot.cc
@@ -329,7 +329,7 @@ WaterfallDisplayPlot::WaterfallDisplayPlot(QWidget* parent)
   // MidButton for the panning
   // RightButton: zoom out by 1
   // Ctrl+RighButton: zoom out to full size
-  _zoomer = new WaterfallZoomer(canvas(), 0);
+  _zoomer = new WaterfallZoomer(dynamic_cast<QwtPlotCanvas *>(canvas()), 0);
 #if QWT_VERSION < 0x060000
   _zoomer->setSelectionFlags(QwtPicker::RectSelection | QwtPicker::DragSelection);
 #endif
@@ -343,7 +343,7 @@ WaterfallDisplayPlot::WaterfallDisplayPlot(QWidget* parent)
   _panner->setMouseButton(Qt::MidButton);
 
   // emit the position of clicks on widget
-  _picker = new QwtDblClickPlotPicker(canvas());
+  _picker = new QwtDblClickPlotPicker(dynamic_cast<QwtPlotCanvas *>(canvas()));
 #if QWT_VERSION < 0x060000
   connect(_picker, SIGNAL(selected(const QwtDoublePoint &)),
    this, SLOT(OnPickerPointSelected(const QwtDoublePoint &)));
diff --git a/gr-qtgui/lib/spectrumdisplayform.cc b/gr-qtgui/lib/spectrumdisplayform.cc
index dd9011d..0da804b 100644
--- a/gr-qtgui/lib/spectrumdisplayform.cc
+++ b/gr-qtgui/lib/spectrumdisplayform.cc
@@ -50,9 +50,9 @@ SpectrumDisplayForm::SpectrumDisplayForm(QWidget* parent)
   MaxHoldCheckBox_toggled( false );
 
   WaterfallMaximumIntensityWheel->setRange(-200, 0);
-  WaterfallMaximumIntensityWheel->setTickCnt(50);
+  WaterfallMaximumIntensityWheel->setTickCount(50);
   WaterfallMinimumIntensityWheel->setRange(-200, 0);
-  WaterfallMinimumIntensityWheel->setTickCnt(50);
+  WaterfallMinimumIntensityWheel->setTickCount(50);
   WaterfallMinimumIntensityWheel->setValue(-200);
 
   _peakFrequency = 0;
@@ -597,13 +597,13 @@ void
 SpectrumDisplayForm::WaterfallAutoScaleBtnCB()
 {
   double minimumIntensity = _noiseFloorAmplitude - 5;
-  if(minimumIntensity < WaterfallMinimumIntensityWheel->minValue()){
-    minimumIntensity = WaterfallMinimumIntensityWheel->minValue();
+  if(minimumIntensity < WaterfallMinimumIntensityWheel->minimum()){
+    minimumIntensity = WaterfallMinimumIntensityWheel->minimum();
   }
   WaterfallMinimumIntensityWheel->setValue(minimumIntensity);
   double maximumIntensity = _peakAmplitude + 10;
-  if(maximumIntensity > WaterfallMaximumIntensityWheel->maxValue()){
-    maximumIntensity = WaterfallMaximumIntensityWheel->maxValue();
+  if(maximumIntensity > WaterfallMaximumIntensityWheel->maximum()){
+    maximumIntensity = WaterfallMaximumIntensityWheel->maximum();
   }
   WaterfallMaximumIntensityWheel->setValue(maximumIntensity);
   waterfallMaximumIntensityChangedCB(maximumIntensity);

diff --git a/gnuradio-core/src/lib/general/gr_random_pdu.h b/gnuradio-core/src/lib/general/gr_random_pdu.h
index 8b8beb6..6323fc8 100644
--- a/gnuradio-core/src/lib/general/gr_random_pdu.h
+++ b/gnuradio-core/src/lib/general/gr_random_pdu.h
@@ -28,8 +28,10 @@
 #include <gr_message.h>
 #include <gr_msg_queue.h>
 
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/random.hpp>
 #include <boost/generator_iterator.hpp>
+#endif
 
 class gr_random_pdu;
 typedef boost::shared_ptr<gr_random_pdu> gr_random_pdu_sptr;
diff --git a/gnuradio-core/src/lib/general/gri_fft.h b/gnuradio-core/src/lib/general/gri_fft.h
index 65e9d04..9fd6801 100644
--- a/gnuradio-core/src/lib/general/gri_fft.h
+++ b/gnuradio-core/src/lib/general/gri_fft.h
@@ -28,7 +28,9 @@
 
 #include <gr_core_api.h>
 #include <gr_complex.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/thread.hpp>
+#endif
 
 /*! \brief Helper function for allocating complex fft buffers
  */
diff --git a/gnuradio-core/src/lib/io/gr_file_sink_base.h b/gnuradio-core/src/lib/io/gr_file_sink_base.h
index 8a70cee..e9332ae 100644
--- a/gnuradio-core/src/lib/io/gr_file_sink_base.h
+++ b/gnuradio-core/src/lib/io/gr_file_sink_base.h
@@ -24,7 +24,9 @@
 #define INCLUDED_GR_FILE_SINK_BASE_H
 
 #include <gr_core_api.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/thread.hpp>
+#endif
 #include <cstdio>
 
 /*!
diff --git a/gnuradio-core/src/lib/io/gr_file_source.h b/gnuradio-core/src/lib/io/gr_file_source.h
index 0478fba..59662fd 100644
--- a/gnuradio-core/src/lib/io/gr_file_source.h
+++ b/gnuradio-core/src/lib/io/gr_file_source.h
@@ -25,7 +25,9 @@
 
 #include <gr_core_api.h>
 #include <gr_sync_block.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/thread/mutex.hpp>
+#endif
 
 class gr_file_source;
 typedef boost::shared_ptr<gr_file_source> gr_file_source_sptr;
diff --git a/gnuradio-core/src/lib/io/gr_socket_pdu.h b/gnuradio-core/src/lib/io/gr_socket_pdu.h
index 2fedb31..87fbb1c 100644
--- a/gnuradio-core/src/lib/io/gr_socket_pdu.h
+++ b/gnuradio-core/src/lib/io/gr_socket_pdu.h
@@ -28,8 +28,10 @@
 #include <gr_message.h>
 #include <gr_msg_queue.h>
 #include <gr_stream_pdu_base.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/array.hpp>
 #include <boost/asio.hpp>
+#endif
 #include <iostream>
 
 class gr_socket_pdu;
diff --git a/gnuradio-core/src/lib/io/gr_wavfile_sink.h b/gnuradio-core/src/lib/io/gr_wavfile_sink.h
index 162151b..b377557 100644
--- a/gnuradio-core/src/lib/io/gr_wavfile_sink.h
+++ b/gnuradio-core/src/lib/io/gr_wavfile_sink.h
@@ -26,7 +26,9 @@
 #include <gr_core_api.h>
 #include <gr_sync_block.h>
 #include <gr_file_sink_base.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/thread.hpp>
+#endif
 
 class gr_wavfile_sink;
 typedef boost::shared_ptr<gr_wavfile_sink> gr_wavfile_sink_sptr;
diff --git a/gnuradio-core/src/lib/io/i2c.h b/gnuradio-core/src/lib/io/i2c.h
index 6b7f25a..89729b0 100644
--- a/gnuradio-core/src/lib/io/i2c.h
+++ b/gnuradio-core/src/lib/io/i2c.h
@@ -24,7 +24,9 @@
 #define INCLUDED_I2C_H
 
 #include <gr_core_api.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/shared_ptr.hpp>
+#endif
 
 class i2c;
 typedef boost::shared_ptr<i2c> i2c_sptr;
diff --git a/gnuradio-core/src/lib/io/i2c_bbio.h b/gnuradio-core/src/lib/io/i2c_bbio.h
index 6bf47b9..ff79f22 100644
--- a/gnuradio-core/src/lib/io/i2c_bbio.h
+++ b/gnuradio-core/src/lib/io/i2c_bbio.h
@@ -24,7 +24,10 @@
 #define INCLUDED_I2C_BBIO_H
 
 #include <gr_core_api.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/shared_ptr.hpp>
+#endif
+
 
 class i2c_bbio;
 typedef boost::shared_ptr<i2c_bbio>  i2c_bbio_sptr;
diff --git a/gnuradio-core/src/lib/io/microtune_xxxx.h b/gnuradio-core/src/lib/io/microtune_xxxx.h
index b2646d3..b76f5a1 100644
--- a/gnuradio-core/src/lib/io/microtune_xxxx.h
+++ b/gnuradio-core/src/lib/io/microtune_xxxx.h
@@ -24,7 +24,10 @@
 #define INCLUDED_MICROTUNE_XXXX_H
 
 #include <gr_core_api.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/shared_ptr.hpp>
+#endif
+
 
 class i2c;
 typedef boost::shared_ptr<i2c> i2c_sptr;
diff --git a/gnuradio-core/src/lib/io/microtune_xxxx_eval_board.h b/gnuradio-core/src/lib/io/microtune_xxxx_eval_board.h
index 7fd784a..7a1e3fb 100644
--- a/gnuradio-core/src/lib/io/microtune_xxxx_eval_board.h
+++ b/gnuradio-core/src/lib/io/microtune_xxxx_eval_board.h
@@ -24,7 +24,9 @@
 #define INCLUDED_MICROTUNE_XXXX_EVAL_BOARD_H
 
 #include <gr_core_api.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/shared_ptr.hpp>
+#endif
 
 class microtune_xxxx;
 
diff --git a/gnuradio-core/src/lib/io/ppio.h b/gnuradio-core/src/lib/io/ppio.h
index d99f7bf..b2b3003 100644
--- a/gnuradio-core/src/lib/io/ppio.h
+++ b/gnuradio-core/src/lib/io/ppio.h
@@ -24,7 +24,9 @@
 #define INCLUDED_PPIO_H
 
 #include <gr_core_api.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/shared_ptr.hpp>
+#endif
 
 class ppio;
 typedef boost::shared_ptr<ppio> ppio_sptr;
diff --git a/gnuradio-core/src/lib/io/sdr_1000.h b/gnuradio-core/src/lib/io/sdr_1000.h
index c00608a..8af008c 100644
--- a/gnuradio-core/src/lib/io/sdr_1000.h
+++ b/gnuradio-core/src/lib/io/sdr_1000.h
@@ -24,7 +24,10 @@
 #define INCLUDED_SDR_1000_H
 
 #include <gr_core_api.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/shared_ptr.hpp>
+#endif
+
 
 class ppio;
 typedef boost::shared_ptr<ppio> ppio_sptr;
diff --git a/gnuradio-core/src/lib/runtime/gr_basic_block.h b/gnuradio-core/src/lib/runtime/gr_basic_block.h
index 024159c..81f873c 100644
--- a/gnuradio-core/src/lib/runtime/gr_basic_block.h
+++ b/gnuradio-core/src/lib/runtime/gr_basic_block.h
@@ -26,16 +26,20 @@
 #include <gr_core_api.h>
 #include <gr_runtime_types.h>
 #include <gr_sptr_magic.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/enable_shared_from_this.hpp>
 #include <boost/function.hpp>
+#endif
 #include <gr_msg_accepter.h>
 #include <string>
 #include <deque>
 #include <map>
 #include <gr_io_signature.h>
 #include <gruel/thread.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/foreach.hpp>
 #include <boost/thread/condition_variable.hpp>
+#endif
 #include <iostream>
 
 /*!
diff --git a/gnuradio-core/src/lib/runtime/gr_buffer.h b/gnuradio-core/src/lib/runtime/gr_buffer.h
index 631ee30..b012b49 100644
--- a/gnuradio-core/src/lib/runtime/gr_buffer.h
+++ b/gnuradio-core/src/lib/runtime/gr_buffer.h
@@ -25,7 +25,9 @@
 
 #include <gr_core_api.h>
 #include <gr_runtime_types.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/weak_ptr.hpp>
+#endif
 #include <gruel/thread.h>
 #include <gr_tags.h>
 #include <deque>
diff --git a/gnuradio-core/src/lib/runtime/gr_hier_block2_detail.h b/gnuradio-core/src/lib/runtime/gr_hier_block2_detail.h
index b38dae3..54097c7 100644
--- a/gnuradio-core/src/lib/runtime/gr_hier_block2_detail.h
+++ b/gnuradio-core/src/lib/runtime/gr_hier_block2_detail.h
@@ -25,7 +25,9 @@
 #include <gr_core_api.h>
 #include <gr_hier_block2.h>
 #include <gr_flat_flowgraph.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/utility.hpp>
+#endif
 
 /*!
  * \ingroup internal
diff --git a/gnuradio-core/src/lib/runtime/gr_scheduler.h b/gnuradio-core/src/lib/runtime/gr_scheduler.h
index 6d13032..b4e2e49 100644
--- a/gnuradio-core/src/lib/runtime/gr_scheduler.h
+++ b/gnuradio-core/src/lib/runtime/gr_scheduler.h
@@ -23,7 +23,9 @@
 #define INCLUDED_GR_SCHEDULER_H
 
 #include <gr_core_api.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/utility.hpp>
+#endif
 #include <gr_block.h>
 #include <gr_flat_flowgraph.h>
 
diff --git a/gnuradio-core/src/lib/runtime/gr_select_handler.h b/gnuradio-core/src/lib/runtime/gr_select_handler.h
index c4c3592..4b1dd15 100644
--- a/gnuradio-core/src/lib/runtime/gr_select_handler.h
+++ b/gnuradio-core/src/lib/runtime/gr_select_handler.h
@@ -24,7 +24,9 @@
 #define INCLUDED_GR_SELECT_HANDLER_H
 
 #include <gr_core_api.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/shared_ptr.hpp>
+#endif
 
 class gr_select_handler;
 typedef boost::shared_ptr<gr_select_handler> gr_select_handler_sptr;
diff --git a/gnuradio-core/src/lib/runtime/gr_types.h b/gnuradio-core/src/lib/runtime/gr_types.h
index db13e45..4329210 100644
--- a/gnuradio-core/src/lib/runtime/gr_types.h
+++ b/gnuradio-core/src/lib/runtime/gr_types.h
@@ -24,7 +24,9 @@
 #define INCLUDED_GR_TYPES_H
 
 #include <gr_core_api.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/shared_ptr.hpp>
+#endif
 #include <vector>
 #include <stddef.h>        // size_t
 
diff --git a/gnuradio-core/src/lib/runtime/gr_unittests.h b/gnuradio-core/src/lib/runtime/gr_unittests.h
index 9fbf228..98a5eca 100644
--- a/gnuradio-core/src/lib/runtime/gr_unittests.h
+++ b/gnuradio-core/src/lib/runtime/gr_unittests.h
@@ -33,8 +33,10 @@
 #include <unistd.h>
 #include <string>
 
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/filesystem/operations.hpp>
 #include <boost/filesystem/path.hpp>
+#endif
 
 static std::string get_unittest_path(const std::string &filename){
     boost::filesystem::path path = boost::filesystem::current_path() / ".unittests";
diff --git a/gr-blocks/include/blocks/file_sink_base.h b/gr-blocks/include/blocks/file_sink_base.h
index 3eeb0e6..209e777 100644
--- a/gr-blocks/include/blocks/file_sink_base.h
+++ b/gr-blocks/include/blocks/file_sink_base.h
@@ -24,7 +24,9 @@
 #define INCLUDED_GR_FILE_SINK_BASE_H
 
 #include <blocks/api.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/thread.hpp>
+#endif
 #include <cstdio>
 
 namespace gr {
diff --git a/gr-digital/include/digital/packet_header_default.h b/gr-digital/include/digital/packet_header_default.h
index e4c9945..8ce5680 100644
--- a/gr-digital/include/digital/packet_header_default.h
+++ b/gr-digital/include/digital/packet_header_default.h
@@ -24,7 +24,9 @@
 
 #include <gr_tags.h>
 #include <digital/api.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/enable_shared_from_this.hpp>
+#endif
 
 namespace gr {
   namespace digital {
diff --git a/gr-digital/include/digital_constellation.h b/gr-digital/include/digital_constellation.h
index 5503fb4..6788149 100644
--- a/gr-digital/include/digital_constellation.h
+++ b/gr-digital/include/digital_constellation.h
@@ -27,7 +27,9 @@
 #include <vector>
 #include <math.h>
 #include <gr_complex.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/enable_shared_from_this.hpp>
+#endif
 #include <digital_metric_type.h>
 
 /************************************************************/
diff --git a/gr-digital/include/digital_ofdm_equalizer_base.h b/gr-digital/include/digital_ofdm_equalizer_base.h
index 2fc5cf5..a7a05a3 100644
--- a/gr-digital/include/digital_ofdm_equalizer_base.h
+++ b/gr-digital/include/digital_ofdm_equalizer_base.h
@@ -25,7 +25,9 @@
 #include <digital_api.h>
 #include <gr_tags.h>
 #include <gr_complex.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/enable_shared_from_this.hpp>
+#endif
 
 class digital_ofdm_equalizer_base;
 typedef boost::shared_ptr<digital_ofdm_equalizer_base> digital_ofdm_equalizer_base_sptr;
diff --git a/gr-pager/lib/pager_flex_frame.h b/gr-pager/lib/pager_flex_frame.h
index a2e8f23..da31ee3 100644
--- a/gr-pager/lib/pager_flex_frame.h
+++ b/gr-pager/lib/pager_flex_frame.h
@@ -22,7 +22,9 @@
 #define INCLUDED_PAGER_FLEX_FRAME_H
 
 #include <pager_api.h>
+#ifndef Q_MOC_RUN  // See: https://bugreports.qt-project.org/browse/QTBUG-22829
 #include <boost/shared_ptr.hpp>
+#endif
 
 class pager_flex_frame;
 typedef boost::shared_ptr<pager_flex_frame> pager_flex_frame_sptr;

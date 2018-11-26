bindist:
	rm -rf CCA.app && \
	make -C src CCA && \
	mkdir CCA.app && \
	mkdir CCA.app/Contents && \
	mkdir CCA.app/Contents/Resources && \
	mkdir CCA.app/Contents/MacOS && \
	cp src/CCA CCA.app/Contents/MacOS && \
	cp res/CCA.icns CCA.app/Contents/Resources && \
	cp res/Info.plist CCA.app/Contents && \
	touch CCA.app

clean:
	rm -rf CCA.app && \
	make -C src clean

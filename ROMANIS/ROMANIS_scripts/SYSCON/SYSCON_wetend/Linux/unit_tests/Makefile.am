bin_PROGRAMS= test_timestamp_mcu sync_mcu

test_timestamp_mcu_SOURCES=test_timestamp_mcu.cc
test_timestamp_mcu_LDADD=-lpthread -lstdc++
test_timestamp_mcu_CPPFLAGS=-DSTDERR_MODE  $(AM_CFLAGS)

sync_mcu_SOURCES=sync_mcu.cc
sync_mcu_LDADD=-lpthread -lstdc++
sync_mcu_CPPFLAGS=-DSTDERR_MODE  $(AM_CFLAGS)
install-exec-local:
uninstall-local:

#ifndef _COMPAT_LINUX_ETHERDEVICE_H
#define _COMPAT_LINUX_ETHERDEVICE_H

#include_next <linux/etherdevice.h>

/* Backport ether_addr_equal */
static inline bool ether_addr_equal(const u8 *addr1, const u8 *addr2)
{
    return !compare_ether_addr(addr1, addr2);
}

#endif

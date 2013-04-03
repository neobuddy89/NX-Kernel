#ifndef _COMPAT_LINUX_GENETLINK_H
#define _COMPAT_LINUX_GENETLINK_H

#include_next <linux/genetlink.h>

#define genl_dump_check_consistent(cb, user_hdr, family)

#endif

// Minimal Warden LSM initialization
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/lsm_hooks.h>
#include <linux/security.h>

static int __init warden_init(void)
{
	pr_info("Warden LSM: initializing minimal stub\n");
	return 0;
}

DEFINE_LSM(warden) = {
	.name = "warden",
	.init = warden_init,
};


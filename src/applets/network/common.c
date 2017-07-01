/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2017 Ikey Doherty <ikey@solus-project.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include "util.h"

BUDGIE_BEGIN_PEDANTIC
#include "common.h"
BUDGIE_END_PEDANTIC

const gchar *nm_state_to_icon(NMDeviceState st)
{
        switch (st) {
        case NM_DEVICE_STATE_UNKNOWN:
        case NM_DEVICE_STATE_UNMANAGED:
                return "network-wired-offline-symbolic";
        case NM_DEVICE_STATE_UNAVAILABLE:
                return "network-wired-no-route-symbolic";
        case NM_DEVICE_STATE_FAILED:
                return "network-error-symbolic";
        case NM_DEVICE_STATE_PREPARE:
        case NM_DEVICE_STATE_CONFIG:
        case NM_DEVICE_STATE_IP_CHECK:
        case NM_DEVICE_STATE_IP_CONFIG:
        case NM_DEVICE_STATE_SECONDARIES:
                return "network-wired-acquiring-symbolic";
        case NM_DEVICE_STATE_DISCONNECTED:
        case NM_DEVICE_STATE_DEACTIVATING:
                return "network-wired-disconnected-symbolic";
        case NM_DEVICE_STATE_ACTIVATED:
                return "network-wired-symbolic";
        default:
                return "network-error-symbolic";
        }
}

/*
 * Editor modelines  -  https://www.wireshark.org/tools/modelines.html
 *
 * Local variables:
 * c-basic-offset: 8
 * tab-width: 8
 * indent-tabs-mode: nil
 * End:
 *
 * vi: set shiftwidth=8 tabstop=8 expandtab:
 * :indentSize=8:tabSize=8:noTabs=true:
 */

/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2016-2021 Budgie Desktop Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

#pragma once

#define _STRINGIFY(x) #x

#if defined(__GNUC__)

/**
 * With newer GCC versions, we see compiler warnings simply from including any glib/gtk header.
 * Many of these make it very hard to debug genuine compiler warnings for Budgie itself, which
 * ideally should be completely clear.
 *
 * This provides a quick useful macro to wrap around the inclusion of GTK/GLib header files
 */
#define _BUDGIE_BEGIN_PEDANTIC(COMP) _Pragma(_STRINGIFY(COMP diagnostic push)) _Pragma(_STRINGIFY(COMP diagnostic ignored "-Wpedantic"))

/**
 * End the includes block, i.e. by popping the diagnostic once more
 */
#define _BUDGIE_END_PEDANTIC(COMP) _Pragma(_STRINGIFY(COMP diagnostic pop))

/**
 * Clang unfortunately also defines __GNUC__ meaning a second level of tests
 */
#if defined(__clang__)

/**
 * Specifically use clang in pragma for older versions of Clang that don't understand
 * pragma GCC
 */
#define BUDGIE_BEGIN_PEDANTIC _BUDGIE_BEGIN_PEDANTIC(clang)
#define BUDGIE_END_PEDANTIC _BUDGIE_END_PEDANTIC(clang)
#else /* __clang__ */

/**
 * Specifically use GCC pragma for GCC
 */
#define BUDGIE_BEGIN_PEDANTIC _BUDGIE_BEGIN_PEDANTIC(GCC)
#define BUDGIE_END_PEDANTIC _BUDGIE_END_PEDANTIC(GCC)
#endif

#else /* __GNUC__ */
/**
 * Unknown compiler, don't expose the functionality
 */
#define BUDGIE_BEGIN_PEDANTIC
#define BUDGIE_END_PEDANTIC
#endif

/* Useful macros */

/**
 * Useful during development to silence compiler warnings
 */
#define __budgie_unused__ __attribute__((unused))

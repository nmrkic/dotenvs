/* Watches XKB group (layout) changes and fires a notify-send popup. */
#include <X11/Xlib.h>
#include <X11/XKBlib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char *label_for(int group) {
    switch (group) {
        case 0: return "US";
        case 1: return "Serbian (Cyrillic)";
        case 2: return "Serbian (Latin)";
        default: return "Unknown";
    }
}

int main(void) {
    Display *dpy = XOpenDisplay(NULL);
    if (!dpy) {
        fprintf(stderr, "layout-notify: cannot open display\n");
        return 1;
    }

    int xkb_event, xkb_error, xkb_major = XkbMajorVersion, xkb_minor = XkbMinorVersion;
    if (!XkbLibraryVersion(&xkb_major, &xkb_minor) ||
        !XkbQueryExtension(dpy, NULL, &xkb_event, &xkb_error, &xkb_major, &xkb_minor)) {
        fprintf(stderr, "layout-notify: XKB extension unavailable\n");
        return 1;
    }

    XkbSelectEventDetails(dpy, XkbUseCoreKbd, XkbStateNotify,
                           XkbGroupStateMask, XkbGroupStateMask);

    int last_group = -1;
    XEvent ev;
    while (1) {
        XNextEvent(dpy, &ev);
        if (ev.type != xkb_event) continue;
        XkbEvent *xkb_ev = (XkbEvent *)&ev;
        if (xkb_ev->any.xkb_type != XkbStateNotify) continue;

        int group = xkb_ev->state.group;
        if (group == last_group) continue;
        last_group = group;

        char cmd[256];
        snprintf(cmd, sizeof(cmd),
                 "notify-send -a keyboard -u low -t 1200 "
                 "-h string:x-canonical-private-synchronous:layout-switch "
                 "'Keyboard layout' '%s'",
                 label_for(group));
        system(cmd);
    }

    XCloseDisplay(dpy);
    return 0;
}

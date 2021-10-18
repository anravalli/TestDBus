/*
 * test-client.c
 *
 *  Created on: Sep 17, 2019
 *      Author: Andrea Ravalli
 */
#include <stdio.h>
#include <stdlib.h>

#include "test.h"
#include <glib.h>
#include <glib/gprintf.h>

GMainLoop *loop;

Test *asynch_proxy = NULL;
gint a = 12345;

gboolean exec_test_req_synch(gpointer data)
{
    Test *proxy = (Test*)data;
    static int count = 0;
    g_printf("exec_test_req_synch: #%d\n", count);
    gint out_seq;
    GError *error = NULL;
    gboolean res = test_call_request_sync(proxy, &out_seq, NULL, &error);
    if (res){
        g_printf("request success\n");
    }
    else{
        g_printf("request failed\n");
        g_printf("ERROR: %s", error->message);
    }
    g_printf("completed: #%d\n", count);
    g_printf("returned: #%d\n", out_seq);
    count++;

    return G_SOURCE_CONTINUE;
}

void exec_request_req_finish_cbk(GObject *source_object, GAsyncResult* res, gpointer data)
{
    Test *proxy = (Test*)data;
    g_printf("exec_test_req_finish_cbk\n");
    GError *error = NULL;
    gint out_seq = 0;

    gboolean result = test_call_request_finish(proxy, &out_seq ,res, &error);

    if(result == TRUE)
        g_printf("Result OK for request #%d\n", out_seq);
    else{
        g_printf("Result NOK with error:");
        if (error != NULL)
            g_printf("\n %d:%s\n", error->code, error->message);
        else
            g_printf(" UKNOWN \n");
    }

}

gboolean exec_test_req(gpointer data)
{
    Test *proxy = (Test*)data;
    g_printf("exec_test_req\n");
    test_call_request (
        proxy,
        NULL,
        exec_request_req_finish_cbk,
        proxy);

    return G_SOURCE_CONTINUE;
}

void on_event(Test *proxy, char* msg)
{
    printf("*** RECEIVED EVENT #%s \n", msg);
}

void on_status_changed(Test *proxy, guint st)
{
	printf("*** on_status_changed\n");
}

void g_on_status_changed(Test *proxy, GVariant *params, gpointer data)
{
	printf("*** g_on_status_changed\n");
//	(void)conn;
//	(void)sender;
//	(void)path;
//	(void)interface;

	guint st = 0;
	GVariantIter *properties = NULL;
	const char *key;
	GVariant *value = NULL;
	gchar *signature = g_variant_get_type_string(params);
	g_print("signature is %s\n", signature);
//	if(strcmp(signature, "(sa{sv}as)") != 0) {
//		g_print("Invalid signature for %s: %s != %s", signal, signature, "(sa{sv}as)");
//		goto done;
//	}
//
	g_variant_get(params, "a{sv}",&properties);
	while(g_variant_iter_next(properties, "{&sv}", &key, &value)) {
		//printf("key: %s\n", key);
		signature = g_variant_get_type_string(value);
		printf("value signature is: %s\n", signature);
		g_variant_get(value, signature, &st);
		printf("%s: %d\n", key, st);
	}
}

void bus_ready_cbk(GObject *source_object, GAsyncResult *res, gpointer data){
    g_printf("bus_ready_cbk\n");
    int rate = *(int*)data;
    GError *error = NULL;
    //GAsyncResult *res = NULL;
    asynch_proxy = test_proxy_new_for_bus_finish (res, &error);
    if (error)
        g_printf("ERROR: %s", error->message);
    if (asynch_proxy != NULL){
        //g_timeout_add_seconds(rate, exec_test_req, asynch_proxy);
        g_signal_connect(asynch_proxy, "event", G_CALLBACK(on_event), NULL);

        //g_signal_connect(asynch_proxy, "PropertiesChanged", G_CALLBACK(on_status_changed), NULL);
        g_signal_connect(asynch_proxy, "g-properties-changed", G_CALLBACK(g_on_status_changed), NULL);
    }
}

int main(int argc, char **argv) {
    gboolean async_on = FALSE;
    int req_rate = 1; //secs

    Test *proxy;
    GError *error = NULL;

    int arg_idx = 1;
    while(arg_idx < argc){
        g_printf("-arg[%d]: %s\n", arg_idx,argv[arg_idx]);
        if (!strcmp(argv[arg_idx], "-a")){
            async_on = TRUE;
        }
        arg_idx++;
    }

    loop = g_main_loop_new(NULL, FALSE);

    if (async_on) {
        test_proxy_new_for_bus(G_BUS_TYPE_SESSION, G_DBUS_PROXY_FLAGS_NONE,
                "org.softcoredesign.properties.Test", "/org/softcoredesign/properties/Test", NULL, bus_ready_cbk, &req_rate);
    }
    else {
        proxy = test_proxy_new_for_bus_sync(G_BUS_TYPE_SESSION, G_DBUS_PROXY_FLAGS_NONE,
                "org.softcoredesign.properties.Test", "/org/softcoredesign/properties/Test", NULL, &error);
        if (error)
            g_printf("ERROR: %s", error->message);
        //g_timeout_add_seconds(req_rate, exec_test_req_synch, proxy);
        g_signal_connect(proxy, "event", G_CALLBACK(on_event), NULL);
        //g_signal_connect(proxy, "PropertiesChanged", G_CALLBACK(on_status_changed), NULL);
        g_signal_connect(proxy, "g-properties-changed", G_CALLBACK(g_on_status_changed), NULL);
    }



    g_main_loop_run(loop);
    g_printf("exiting program.\n");
    g_object_unref(proxy);

    return 0;
}

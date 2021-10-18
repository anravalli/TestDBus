/*
 ============================================================================
 Name        : dummy_service.c
 Author      : Andrea Ravalli
 Version     :
 Copyright   : Your copyright notice
 Description : Dummy Service for K1OS
 ============================================================================
 */

#include <stdio.h>
#include <stdlib.h>

#include <glib.h>
#include <test.h>

typedef struct _Application
{
	GMainLoop *app_loop;
	Test *skeleton;
	guint owning_name;
	int req_count;
	guint status;
} Application;

gboolean update_status(gpointer data)
{
	printf("updating status\n");
	Application *self = (Application *)data;
	self->status += 10;
	test_set_status(self->skeleton, self->status);
	printf("...new status is %d\n", self->status);
	return G_SOURCE_CONTINUE;
}

void on_handle_request(Test *skeleton, GDBusMethodInvocation *invocation, gpointer data)
{
	Application* self = (Application*)data;

    self->req_count++;
    printf("Received request #%d\n", self->req_count);

    //g_printf("...completing #%d\n", self->req_count);
    test_complete_request(skeleton, invocation, self->req_count);
}

void on_name_acquired(GDBusConnection *connection, const gchar *name, gpointer data) {
    printf("--- Name Acquired ---\n");
    Application* self = (Application*)data;

    self->skeleton = test_skeleton_new();

    g_dbus_interface_skeleton_export(G_DBUS_INTERFACE_SKELETON(self->skeleton), connection,
            "/org/softcoredesign/properties/Test", NULL);

    g_signal_connect(self->skeleton, "handle_request", G_CALLBACK(on_handle_request), data);

    g_timeout_add_seconds(10,update_status,self);
}

int application_init(Application* self)
{

	/*
	 * acquire bus name;
	 */
	self->owning_name = g_bus_own_name(G_BUS_TYPE_SESSION,
			"org.softcoredesign.properties.Test", G_BUS_NAME_OWNER_FLAGS_NONE, NULL,
			on_name_acquired, NULL, self, NULL);

	gint int_result = 0;
	if (self->owning_name == 0)
		int_result = -1;

	return int_result;
}

int application_deinit(Application* self)
{
    printf("--- deinit ---\n");



    return 0;
}

Application *application_create()
{
    Application *app = g_new0(Application, 1);

    if (app != NULL)
    {
        //app->config = service_configuration_instance();
        app->app_loop = g_main_loop_new(NULL, FALSE);

        if( app->app_loop == NULL)
		{
			free(app);
			app = NULL;
		}
    }

    return app;
}

int application_run(Application* _self)
{
    printf("=============== server running =============\n");

	g_main_loop_run(_self->app_loop);

	printf("main loop terminated");

	return 0;
}

int main(int argc, const char** argv)
{

    int ret = -1;

    printf("=============== server start =============\n");
    /*
     * start application
     */
    Application *application = application_create();
    if (application != NULL) {
        int init_status = application_init(application);
        if (!init_status) {
            ret = application_run(application);
        }
        if(application->owning_name != 0)
        	g_bus_unown_name(application->owning_name);
        if(application->app_loop != NULL)  {
            g_main_loop_unref(application->app_loop);
        }
    }
    printf("=============== closing server =============\n");

    return ret;

}

#ifndef __HALLON__
  #define __HALLON__
  
  #include <ruby.h>
  #include <pthread.h>
  
  #ifdef HAVE_LIBSPOTIFY_API_H
  #  include <libspotify/api.h>
  #else
  #  include <spotify/api.h>
  #endif

  /*
    Initializers for the other classes.
  */
  void Init_Session(VALUE);
#endif
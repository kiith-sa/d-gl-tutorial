======================================================
Starting game development with OpenGL and D (on Linux)
======================================================


**WARNING**

This tutorial has not been thoroughly tested. Especially near the beginning.
May not be too useful yet without a GL-literate human nearby.

Some example code based on `opengl-tutorial.org
<http://www.opengl-tutorial.org/beginners-tutorials/tutorial-2-the-first-triangle/>`_.

--------------
First triangle
--------------


This tutorial explains how to get started with writing games in the `D
programming language <http://dlang.org>`_ by creating a very simple graphics
application drawing a triangle using OpenGL (**modern** OpenGL, not that old
immediate mode stuff. If you don't know what immediate mode is, good for uou).
Instead of directly using the operating system to create a window and set up
OpenGL we're going to be using `SDL2 <http://libsdl.org>`_, which allows us to
write code that will work in just about any `*` platform (not like
``Windows``/``Linux``/``OSX`` any, but like
``Windows``/``Linux``/``Android``/``AmigaOS``/``Haiku``/``Dreamcast``/etcetc
any.).

That said, this is a Linux tutorial. The code will be portable between
platforms, but the tutorial might miss some information needed to compile it.

.. admonition:: *
   
   That is, it would if the D compiler worked on anything that's not a PC
   (x86). Which it kinda does now, with GDC supporting ARM, but use at your 
   own risk.


* First, be sure you have an up-to-date graphics driver.

  You also need the SDL2 library and may need some libraries to be able to 
  use OpenGL.

  On debians/ubuntus/mints::

     sudo apt-get install libgl1-mesa-dev libsdl2-dev

  (On fedoras and arches, suses and gentoos, puppies and mageias, figure it out
  yourself. It won't be too different. Usually. If you figure it out, pull
  requests welcome.)

* And for D, we need a D compiler.

  GDC may be good enough (debians/ubuntus/mints)::

     sudo apt-get install gdc

  But I suggest the DMD compiler for start, mainly because I used DMD when 
  writing the tutorial (DMD compiles faster. GDC produces faster code).
  Get DMD `here <http://dlang.org/download.html>`_ .

* Create a directory for this tutorial and in it create a file called
  ``triangle.d`` with a ``main()`` function::

     import std.stdio;
     int main(string[] args)
     {
         writeln("This should eventually draw a triangle");
     } 

* Compile it: ``rdmd triangle.d``
* You should now have a binary named ``triangle.exe`` or ``triangle``
  depending on platform. Try running it from console to see if it prints 
  ``This should eventually draw a triangle``.

* Get DerelictUtil. Derelict is a project providing D bindings for many
  libraries useful for game development, and DerelictUtil is the base for all
  these wrappers. Derelict almost always provides API identical to the original
  libraries, so for example OpenGL tutorials written for C are still useful in
  D with Derelict.

  Download DerelictUtil `here
  <https://github.com/DerelictOrg/DerelictUtil/archive/master.zip>`_.

  Unpack the archive into the tutorial directory.
  The directory should now look like this::
     
     DerelictUtil-master
     triangle.d
     triangle.exe or triangle

* Get DerelictSDL2 and DerelictGL3. SDL is a minimalistic library providing
  a OS-independent interface to functionality a game needs from an OS, such as
  windowing, simple 2D graphics, sound, input, etc.  DerelictGL3 is the
  Derelict wrapper for *all* OpenGL versions (not just OpenGL 3 like the name
  suggests).

  Download `DerelictSDL2
  <https://github.com/DerelictOrg/DerelictSDL2/archive/master.zip>`_ and
  `DerelictGL3
  <https://github.com/DerelictOrg/DerelictGL3/archive/master.zip>`_ and unpack
  into the tutorial directory.  The directory should now look like this::

     DerelictUtil-master
     DerelictSDL2-master
     DerelictGL3-master
     triangle.d
     triangle.exe or triangle


* Derelict uses dynamic linking to load SDL and other libraries. On Linux we
  need the ``dl`` library for this. Also, we need to import the libraries we'll
  be using. Add the following code to ``triangle.d`` (someplace between
  ``import std.stdio`` and the ``main()`` function)::

     import derelict.sdl2.sdl;
     import derelict.opengl3.gl3;
     import derelict.util.exception;

     version(linux)
     {
         pragma(lib, "dl");
     }

  ``import derelict.sdl2.sdl;`` allows us to use SDL while ``import
  derelict.opengl3.gl3;`` provides access to OpenGL 3 and newer, but not to the
  old, deprecated functions of OpenGL 1 and 2.  ``import
  derelict.util.exception;`` is needed to print any errors thrown by Derelict.

* To use SDL2 and OpenGL we need to load the libraries. Add this to the
  ``main()`` function::

      // Load SDL2 and GL.
      try
      {
          DerelictSDL2.load();
          DerelictGL3.load();
      }
      // Print errors, if any.
      catch(SharedLibLoadException e)
      {
          writeln("SDL2 or GL not found: " ~ e.msg);
      }
      catch(SymbolLoadException e)
      {
          writeln("Missing SDL2 or GL symbol (old version installed?): " ~ e.msg);
      }

      // When done, unload the libraries.
      scope(exit)
      {
          DerelictGL3.unload();
          DerelictSDL2.unload();
      }

  The code in ``scope(exit)`` will run before the ``main()`` function exits,
  either because the program finished normally or because there was an error.
  In D it is simpler to put cleanup code right after the code it is supposed to
  clean up.

* To test this, we need to tell the compiler where to find Derelict.  This can
  be done by specifying *import directories* for the ``rdmd`` command.  To find
  the Derelict modules, ``rdmd`` must see the ``source`` subdirectories of the
  ``DerelictXXX-master`` directories.

  This makes the compilation command a bit more complicated::

     rdmd --build-only -I./DerelictGL3-master/source/ -I./DerelictSDL2-master/source/ -I./DerelictUtil-master/source/ triangle.d

  To avoid repetitive typing/copypasting, we can put this into a shell script:

  - Create a new file called ``compile.sh`` in the tutorial directory with 
    the following contents::

       #!/bin/sh

       rdmd --build-only -I./DerelictGL3-master/source/ -I./DerelictSDL2-master/source/ -I./DerelictUtil-master/source/ triangle.d

  - Make the file executable: ``chmod +x compile.sh``.
  
  Now we can compile our code by typing ``./compile.sh`` instead of using
  ``rdmd`` directly.

* To draw with OpenGL we need to create a window and an OpenGL *context*.  The
  context stores all OpenGL state. From `opengl.org
  <http://www.opengl.org/wiki/OpenGL_Context>`_::

     An OpenGL context represents many things. A context stores all of the
     state associated with this instance of OpenGL. It represents the
     (potentially visible) default framebuffer that rendering commands will
     draw to when not drawing to a framebuffer object. Think of a context as an
     object that holds all of OpenGL; when a context is destroyed, OpenGL is
     destroyed.

  But even before creating the window, we need to initialize SDL. For now 
  we only need its video (graphics) subsystem::

    // Initialize SDL Video subsystem.
    if(SDL_Init(SDL_INIT_VIDEO) < 0)
    {
        // SDL_Init returns a negative number on error.
        writeln("SDL Video subsystem failed to initialize");
        return 1;
    }
    // Deinitialize SDL at exit.
    scope(exit)
    {
        SDL_Quit();
    }

* Now we will create a window. Before creating it we need to set various OpenGL
  parameters that will affect the window. We will use a *core profile OpenGL
  3.2* context. Core profile means we cannot use functions from older OpenGL
  version that have been deprecated. We use OpenGL 3.2 only because it's modern
  but still old enough to run on most graphics cards.  If you want something
  newer, fell free to increase the version number.

  The window we will draw into will be a 32bit RGBA window with 8 bits per
  channel (red, green, blue, alpha). (To be precise these attributes affect 
  the *framebuffer*, not window, but for now we'll not differentiate between 
  them).

  Add the following code::
     
     // OpenGL 3.2 core profile.
     // and the core profile (i.e. no deprecated functions)
     SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
     SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
     SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE); 

     // 32bit RGBA window
     SDL_GL_SetAttribute(SDL_GL_RED_SIZE,     8);
     SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE,   8);
     SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE,    8);
     SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE,   8);
     // Double buffering to avoid tearing
     SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
     // Depth buffer. Not useful when drawing a triangle, but almost always 
     // useful when drawing 3D
     SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE,   24);

     // Create a centered 640x480 OpenGL window named "Triangle"
     SDL_Window* window = SDL_CreateWindow("Triangle", 
                                           SDL_WINDOWPOS_CENTERED,
                                           SDL_WINDOWPOS_CENTERED,
                                           640, 480,
                                           SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
     // Exit if window creation fails.
     if(null is window)
     {
         writeln("Failed to create the application window");
         return 1;
     }
     // Destroy the window at exit.
     scope(exit)
     {
         SDL_DestroyWindow(window);
     }

  The SDL_Window type provides access to the window, although in this tutorial 
  we will not use it.

* Now we can finally create the OpenGL context::

     // Create an OpenGL context for our window.
     SDL_GLContext context = SDL_GL_CreateContext(window);
     // Delete the GL context when we're done.
     scope(exit)
     {
         SDL_GL_DeleteContext(context);
     }
     // Load all OpenGL functions and extensions supported by Derelict.
     DerelictGL3.reload();

* Most games and other graphics applications are just infinite loops 
  detecting and reacting to events such as keypresses. In a simple OpenGL 
  application, an iteration of such loop is one frame drawn to the screen.

  We will create a new function for all code that happens inside each frame.
  Add the following code before the ``main()`` function::

     bool frame(SDL_Window* window)
     {
         // Read all waiting events
         SDL_Event e;
         while(SDL_PollEvent(&e) != 0) 
         {
             // Quit if the user closes the window or presses Q
             if(e.type == SDL_QUIT) 
             {
                 return false;
             } 
             else if(e.type == SDL_KEYDOWN)
             {
                 //Select surfaces based on key press 
                 switch(e.key.keysym.sym)
                 { 
                     case SDLK_q:
                         return false;
                     default:
                         break;
                 } 
             } 
         }
     
         // Clear the back buffer with a red background (parameters are R, G, B, A)
         glClearColor(1.0, 0.0, 0.0, 1.0);
         glClear(GL_COLOR_BUFFER_BIT);
         // Swap the back buffer to the front, showing it in the window.
         SDL_GL_SwapWindow(window);
     
         return true;
     }

  The ``frame()`` function returns ``true`` if it finishes normally and
  ``false`` if the user wants to exit the program.

  The ``while`` loop at the beginning of the frame looks for events and returns
  ``false`` if it notices a ``SDL_QUIT`` event (for example if the user closes
  the window) or if the ``Q`` key is pressed on the keyboard.

  ``glClearColor()`` is an OpenGL function that specifies the default
  (background) color of the window. When using OpenGL ``glClear()`` is usually 
  used to clear the window to background color so we don't draw over image 
  from the previous frame. For now we will just paint the entire window red.

  As we're using double buffering, all our draws affect the *back* buffer while
  the *front* buffer from the previous frame is shown on the window.  When done
  drawing a frame, we call ``SDL_GL_SwapWindow()`` to swap the front and back
  buffer; our former back buffer with a finished image shows up on the screen
  and the former front buffer is reused to draw the next frame.

* Now we need the event loop, which will use the ``frame()`` function.
  Add the following code to the ``main()`` function::

     for(;;)
     {
         if(!frame(window))
         {
             return 0;
         }
     }

  If ``frame()`` returns false, ``main()`` returns 0, indicating a successful
  shutdown.

* Now I suggest you try to compile this (remember ``compile.sh`` ?) and try to
  run it. You might have made some mistake since the last compile. If so,
  figure it out and fix it.

* Now that we have a nice red window, but we would like to actually draw
  something. OpenGL is a very powerful API but this power also means something
  basic such as "draw a triangle" is not really that basic. We need to describe
  the triangle (as 3 points, or *vertices* defined in 3D space by their X,
  Y and Z coordinate), pass that description to OpenGL and then draw it.  But
  even that "drawing" is non-trivial. Our triangle will be drawn by set of
  programs called *shaders*. In the simplest case, we need two of these:
  a *vertex shader* which will process the vertices (it might, for example,
  transform their position, rotating, moving or resizing a model) and
  a *fragment shader* (sometimes also called *pixel shader*) which will
  determine the color of each pixel covered by the triangle.

  For now, we'll focus on describing the triangle. We will create a new data 
  type (struct) to represent a 3D vertex. Add the following code somewhere 
  between the imports and functions in ``triangle.d``::

     struct Vertex
     {
         float x,y,z;
     }

  This data structure consists of 3 floating point numbers, each 4 bytes wide.

* We need to create a *Vertex Array Object* (or *VAO*) to represent our
  triangle.  For now, all we need to know is that we use VAOs to represent
  geometry.

  Add the following code to ``main()``, right before the event loop 
  (the ``for(;;)`` cycle)::
     
    // Create the Vertex Array Object
    GLuint vertexArrayID;
    glGenVertexArrays(1, &vertexArrayID);
    glBindVertexArray(vertexArrayID);
     

  The reality may be a bit more complicated, but ``glGenVertexArrays()`` can be
  thought of as a function to *create* an array object. In this case we tell it
  to create one array object and store an ID identifying it in
  ``vertexArrayID``.

  The ``glBindVertexArray()`` call tells OpenGL that any following OpenGL calls 
  that apply to a VAO will apply to this here VAO we told it to use.

* Now we need to tell OpenGL what the triangle we want to draw looks like.
  First, we create an array with the 3 vertices (points) defining our triangle.
  Add the following code right after the VAO creation::

     // XYZ coordinates of vertices of our triangle
     auto vertices = [Vertex(-1, -1, 0), Vertex(1, -1, 0), Vertex(0, 1, 0)];

  (``auto`` means D will figure out the type so we save some space)

  And then we need to pass this data to OpenGL::

     GLuint vertexBufferID;
     // Create a new vertex buffer and write its ID into vertexBufferID
     glGenBuffers(1, &vertexBufferID);
     // The following vertex buffer calls will work with the buffer specified by
     // vertexBufferID
     glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID);
     // Copy vertices into the vertex buffer.
     // Usually the means "copy to the VRAM"
     glBufferData(GL_ARRAY_BUFFER,
                  vertices.length * Vertex.sizeof,
                  vertices.ptr,
                  GL_STATIC_DRAW);

  What we do here is that we create a *VBO*, or a *Vertex Buffer Object* and 
  copy the ``vertices`` array into it. In simplified terms, a VBO can be 
  thought of as an array in graphics card memory. (it may not *really* 
  be in graphics card memory, but that's not important for now).

  So, ``glGenBuffers()``, similarly to ``glGenVertexArrays()``, creates a VBO.
  ``glBindBuffer()`` tells GL to use *this** VBO in the following calls.
  ``glBufferData()`` copies ``vertices.length * Vertex,sizeof`` bytes of data
  starting at the beginning of ``vertices``, or ``vertices.ptr``  to the vertex
  buffer. In other words, it copies the whole ``vertices`` array (OpenGL
  figures out how to allocate the space to copy to).  We'll ignore the other
  parameters for now.
     

  
* OK, so now we can start drawing. Kinda. Not really. Let's go back to the 
  ``frame()`` function. Remember the drawing is done after clearing the 
  back buffer and before swapping the back buffer into the front of the window?
  Add the following code between ``glClear()`` and ``SDL_GL_SwapWindow()``::

     // Use the first slot for a vertex attribute array
     glEnableVertexAttribArray(0);
     glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID);
     // Tell GL where the vertex attribute is
     glVertexAttribPointer(
        0,            // We're using attribute 0
        3,            // Number of coordinates (we have 3D vertices, so 3)
        GL_FLOAT,     // Type of coordinates (float)
        GL_FALSE,
        0,
        cast(void*)0  // Start at the beginning (0) of the vertex buffer
     );
     
     // Draw. Sorta. 3 vertices starting from index 0.
     glDrawArrays(GL_TRIANGLES, 0, 3); 

  OK, so the ``glEnableVertexAttribArray()`` tells we're vertex attribute slot
  0. Basically we assign numbers to attributes we use in a single draw call,
  and here we use just one so we just pick the first slot. Vertex attribute 
  is any data that changes for each vertex. In this case, that is the vertex 
  itself, or its position. In more complex code you might also have 
  texture coordinates, normals, colors and so on.

  ``glBindBuffer()`` tells which VBO GL should draw from.
  ``glVertexAttribPointer()`` tells GL where exactly to find a vertex attribute
  and what its format is. So we tell it that attribute ``0`` has 3 coordinates
  (x, y, z members of the Vertex struct) which are floats, and that the first
  vertex is at index 0 (the beginning) of the VBO. We will ignore the other
  parameters for now.

  Finally, ``glDrawArrays()`` draws the triangle, We tell it to group the
  vertex attributes in triplets, each triplet a triangle. We just have one.  We
  tell it to start at index 0 (relative to where we pointed GL to with
  ``glVertexAttribPointer()``). And we tell it to use 3 vertices.

  Don't go compiling this yet. We need to pass the vertex buffer ID to frame().
  Update the top of the ``frame()`` function (*signature*)::

    bool frame(SDL_Window* window, GLuint vertexBufferID)

  And update the code that calls ``frame()``::

    if(!frame(window, vertexBufferID))

  Now, if you compile this, you might see something. Or you might not.
  The code is not complete but your driver and graphics card may figure out 
  what you want. For example on Radeon 6700 with open source drivers on Linux 
  I see a white triangle. That doesn't mean you'll see anything.

  We've passed OpenGL 3 vertices, each with 3 coordinates and tell it to draw
  a triangle.  But we didn't tell it *how* to draw that triangle.

* So now we have to do shaders. Shaders are programs, resembling simple C with
  all the ugliness of a C toolchain.  Meaning we have to compile them and link
  them. We will add a new function, ``compileShaders()``::

     GLuint compileShaders(string vertexSrc, string fragmentSrc)
     {
         // Create the shaders
         GLuint vertexShaderID = glCreateShader(GL_VERTEX_SHADER);
         GLuint fragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);
     
         import std.string;
         // Compile the vertex shader
         writeln("we're about to attempt compiling a vertex shader");
         auto vertexZeroTerminated = toStringz(vertexSrc);
         glShaderSource(vertexShaderID, 1, &vertexZeroTerminated, null);
         glCompileShader(vertexShaderID);
     
         // Use this to determine how much to allocate if infoLog is too short
         // glGetShaderiv(vertexShaderID, GL_INFO_LOG_LENGTH, &infoLogLength);
     
         // Check for errors
         GLint compiled;
         glGetShaderiv(vertexShaderID, GL_COMPILE_STATUS, &compiled);
         char[1024 * 8] infoLog;
         glGetShaderInfoLog(vertexShaderID, infoLog.length, null, infoLog.ptr);
         import core.stdc.stdio;
         writeln("vertex shader info log:");
         puts(infoLog.ptr);
         if(!compiled)
         {
             throw new Exception("Failed to compile vertex shader " ~ vertexSrc);
         }
     
         // Compile Fragment Shader
         writeln("we're about to attempt compiling a fragment shader");
         auto fragmentZeroTerminated = toStringz(fragmentSrc);
         glShaderSource(fragmentShaderID, 1, &fragmentZeroTerminated, null);
         glCompileShader(fragmentShaderID);
     
         // Check for errors
         glGetShaderiv(fragmentShaderID, GL_COMPILE_STATUS, &compiled);
         glGetShaderInfoLog(fragmentShaderID, infoLog.length, null, infoLog.ptr);
         writeln("fragment shader info log:");
         puts(infoLog.ptr);
         if(!compiled)
         {
             throw new Exception("Failed to compile fragment shader " ~ fragmentSrc);
         }
     
         // Link the program
         writeln("we're about to attempt linking");
         GLuint programID = glCreateProgram();
         glAttachShader(programID, vertexShaderID);
         glAttachShader(programID, fragmentShaderID);
         glLinkProgram(programID);
     
         // Check the program
         GLint linked;
         glGetProgramiv(programID, GL_LINK_STATUS, &linked);
         glGetProgramInfoLog(programID, infoLog.length, null, infoLog.ptr);
         writeln("linking info log:");
         puts(infoLog.ptr);
         if(!linked)
         {
             throw new Exception("Failed to link shaders " ~ vertexSrc ~ " " ~ fragmentSrc);
         }
     
         glDeleteShader(vertexShaderID);
         glDeleteShader(fragmentShaderID);
     
         return programID;
     }

  So, err, this takes source code of a vertex and fragment shader and compiles
  and links them into a *shader program* which we can use when drawing.  The
  code starts by compiling the vertex and fragment shaders, will print any
  compilation warnings or errors (using ``puts()`` from C, because zero
  terminated strings and I was lazy), and then links them together into
  a program.  It will throw an ``Exception`` on failure. You can create
  a fancier exception type if you want, and maybe wrap it in a function that
  loads the sources from files.

  I'm not going to go into deeper details. Just copy and paste this around
  until you need something better. It will probably be good enough for a while.
  If you really want to know the details, google the functions.
     
* OK, so now we can compile shaders, we need some shaders to compile.
  Add the following code into the ``main()`` methods right before the 
  event loop (``for(;;)``)::

     string vertexShaderSrc = 
         q{
             #version 330 core
             layout(location = 0) in vec3 inVertexPosition;
             void main()
             {
                 gl_Position = vec4(inVertexPosition, 1.0);
             }
         };
     string fragmentShaderSrc = 
         q{
             #version 330 core
             out vec3 color;
             void main()
             {
                 color = vec3(1,1,0);
             }
         };
     GLuint programID = compileShaders(vertexShaderSrc, fragmentShaderSrc);

  The vertex shader just passes the coordinates along. For now, we don't need
  to care about that suspicious ``1.0`` coordinate that got added.  In proper
  3D graphics this will get more complicated, but this'll do for now.
  ``gl_Position`` is a builtin variable where we write the final position of
  the vertex.

  The fragment shader is just sets the color to yellow (RGB 1,1,0 or 255,255,0
  in 8bit per channel). Meaning we'll have a yellow triangle.

  What's that `q{}` thing? It's a special way to write strings in D so that
  they can be highlighted as D code. D is based on C, and OpenGL shaders are in
  a C-like language (``GLSL``), so they look pretty much like a part of code,
  even though these are actually plain strings with source code.

  The last line compiles the sources into a program.

* Now we can use the shader program when drawing, but we need to pass it to 
  ``frame()``. Update the code that calls ``frame()``::
        
     if(!frame(window, vertexBufferID, programID))

  And the signature of ``frame()``::
     
     bool frame(SDL_Window* window, GLuint vertexBufferID, GLuint programID)

  Finally, tell GL to use the program by adding this before the ``glDrawArrays()``
  call::

     glUseProgram(programID);

  Now you should see a yellow triangle. Over a red background.  If you don't,
  something's wrong. If so, find what and fix it.



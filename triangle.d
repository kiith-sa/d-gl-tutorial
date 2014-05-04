import std.stdio;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3;
import derelict.util.exception;

version(linux)
{
    pragma(lib, "dl");
}



struct Vertex
{
    float x,y,z;
}


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

bool frame(SDL_Window* window, GLuint vertexBufferID, GLuint programID)
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
    
    glUseProgram(programID);

    // Draw. Sorta. 3 vertices starting from index 0.
    glDrawArrays(GL_TRIANGLES, 0, 3);




    // Swap the back buffer to the front, showing it in the window.
    SDL_GL_SwapWindow(window);

    return true;
};

int main(string[] args)
{
    writeln("This should eventually draw a triangle");

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

    // We want OpenGL 3.2 (change this if you want a newer version),
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


    // Create an OpenGL context for our window.
    SDL_GLContext context = SDL_GL_CreateContext(window);
    // Delete the GL context when we're done.
    scope(exit)
    {
        SDL_GL_DeleteContext(context);
    }
    // Load all OpenGL functions and extensions supported by Derelict.
    DerelictGL3.reload();



    // Create the Vertex Array Object
    GLuint vertexArrayID;
    glGenVertexArrays(1, &vertexArrayID);
    glBindVertexArray(vertexArrayID);

    // XYZ coordinates of vertices of our triangle
    auto vertices = [Vertex(-1, -1, 0), Vertex(1, -1, 0), Vertex(0, 1, 0)];
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



    for(;;)
    {
        if(!frame(window, vertexBufferID, programID))
        {
            return 0;
        }
    }






    return 0;
}

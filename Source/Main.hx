package;


import lime.app.Application;
import lime.graphics.cairo.CairoImageSurface;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLTexture;
import lime.graphics.opengl.GLUniformLocation;
import lime.graphics.Image;
import lime.graphics.RenderContext;
import lime.math.Matrix4;
import lime.utils.Assets;
import lime.utils.Float32Array;

import pi_xy.Pixelimage;
import pi_xy.pixel.Pixel32;
import haxe.io.UInt8Array;
import iterMagic.Img;

#if flash
import flash.display.Bitmap;
#end


class Main extends Application {


	private var cairoSurface:CairoImageSurface;
	private var glBuffer:GLBuffer;
	private var glMatrixUniform:GLUniformLocation;
	private var glProgram:GLProgram;
	private var glTexture:GLTexture;
	private var glTextureAttribute:Int;
	private var glVertexAttribute:Int;
	private var image:Image;


	public function new () {

		super ();

	}
    inline
    function createTest(){
        var pixelImage = new Pixelimage( 800, 600 );
        pixelImage.transparent = true;
        pixelImage.simpleRect( 0, 0, pixelImage.width, pixelImage.height, 0xffc9c3c3 );
        pixelImage.transparent = true;
        var Violet      = 0xFF9400D3;
        var Indigo      = 0xFF4b0082;
        var Blue        = 0xFF0000FF;
        var Green       = 0xFF00ff00;
        var Yellow      = 0xFFFFFF00;
        var Orange      = 0xFFFF7F00;
        var Red         = 0xFFFF0000;
        var scale       = 10;
        var pixelTest = new pi_xy.Pixelimage( 80*scale, 80*scale );
        pixelTest.transparent = true;
        var colors = [ Violet, Indigo, Blue, Green, Yellow, Orange, Red ];
        var vertColor = colors[0]; 
        for( x in 0...70*scale ){
            vertColor = colors[ Math.floor( (x/scale) / 10 ) ];
            for( y in 0...768-70-45 ) pixelTest.setARGB( x, y, vertColor );
        }
        pixelTest.gradientShape.triangle( 100, 100, 0xf0ffcf00, 300, 220, 0xf000cfFF, 120, 300, 0xf0cF00FF );
        pixelTest.gradientShape.triangle( 100+120, 100+20, 0xccff0000, 300+120, 220+20, 0xcc0000FF, 120+120, 300+20, 0xcc00ff00 );
        pixelImage.putPixelImage( pixelTest, 45, 45 );
        return pixelImage;
    }

	public override function render (context:RenderContext):Void {

		switch (context.type) {

			case CAIRO:

				var cairo = context.cairo;

				if (image == null && preloader.complete) {

					//image = Assets.getImage ("assets/lime.png");
					image = createTest().imageLime;
					image.format = BGRA32;
					image.premultiplied = true;

					cairoSurface = CairoImageSurface.fromImage (image);

				}

				var r = ((context.attributes.background >> 16) & 0xFF) / 0xFF;
				var g = ((context.attributes.background >> 8) & 0xFF) / 0xFF;
				var b = (context.attributes.background & 0xFF) / 0xFF;
				var a = ((context.attributes.background >> 24) & 0xFF) / 0xFF;

				cairo.setSourceRGB (r, g, b);
				cairo.paint ();

				if (image != null) {

					image.format = BGRA32;
					image.premultiplied = true;

					cairo.setSourceSurface (cairoSurface, 0, 0);
					cairo.paint ();

				}

			case CANVAS:

				var ctx = context.canvas2D;

				if (image == null && preloader.complete) {

					//image = Assets.getImage ("assets/lime.png");
					image = createTest().imageLime;
					ctx.scale(window.scale, window.scale);
					ctx.fillStyle = "#" + StringTools.hex (context.attributes.background, 6);
					ctx.fillRect (0, 0, window.width, window.height);
					ctx.drawImage (image.src, 0, 0, image.width, image.height);

				}

			case DOM:

				var element = context.dom;

				if (image == null && preloader.complete) {

					//image = Assets.getImage ("assets/lime.png");
					image = createTest().imageLime;
					element.style.backgroundColor = "#" + StringTools.hex (context.attributes.background, 6);
					element.appendChild (image.src);

				}

			case FLASH:

				var sprite = context.flash;

				if (image == null && preloader.complete) {

					//image = Assets.getImage ("assets/lime.png");
					image = createTest().imageLime;
					#if flash
					var bitmap = new Bitmap (image.src);
					sprite.addChild (bitmap);
					#end

				}

			case OPENGL, OPENGLES, WEBGL:

				var gl = context.webgl;

				if (image == null && preloader.complete) {

					//image = Assets.getImage ("assets/lime.png");
					image = createTest().imageLime;
					var vertexSource =

						"attribute vec4 aPosition;
						attribute vec2 aTexCoord;
						varying vec2 vTexCoord;

						uniform mat4 uMatrix;

						void main(void) {

							vTexCoord = aTexCoord;
							gl_Position = uMatrix * aPosition;

						}";

					var fragmentSource =

						#if !desktop
						"precision mediump float;" +
						#end
						"varying vec2 vTexCoord;
						uniform sampler2D uImage0;

						void main(void)
						{
							gl_FragColor = texture2D (uImage0, vTexCoord);
						}";

					glProgram = GLProgram.fromSources (gl, vertexSource, fragmentSource);
					gl.useProgram (glProgram);

					glVertexAttribute = gl.getAttribLocation (glProgram, "aPosition");
					glTextureAttribute = gl.getAttribLocation (glProgram, "aTexCoord");
					glMatrixUniform = gl.getUniformLocation (glProgram, "uMatrix");
					var imageUniform = gl.getUniformLocation (glProgram, "uImage0");

					gl.enableVertexAttribArray (glVertexAttribute);
					gl.enableVertexAttribArray (glTextureAttribute);
					gl.uniform1i (imageUniform, 0);

					gl.blendFunc (gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
					gl.enable (gl.BLEND);

					var data = [

						image.width, image.height, 0, 1, 1,
						0, image.height, 0, 0, 1,
						image.width, 0, 0, 1, 0,
						0, 0, 0, 0, 0

					];

					glBuffer = gl.createBuffer ();
					gl.bindBuffer (gl.ARRAY_BUFFER, glBuffer);
					gl.bufferData (gl.ARRAY_BUFFER, new Float32Array (data), gl.STATIC_DRAW);
					gl.bindBuffer (gl.ARRAY_BUFFER, null);

					glTexture = gl.createTexture ();
					gl.bindTexture (gl.TEXTURE_2D, glTexture);
					gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
					gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

					#if js
					gl.texImage2D (gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image.src);
					#else
					gl.texImage2D (gl.TEXTURE_2D, 0, gl.RGBA, image.buffer.width, image.buffer.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, image.data);
					#end

					gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
					gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
					gl.bindTexture (gl.TEXTURE_2D, null);

				}

				var scaledWidth = Std.int(window.width * window.scale);
				var scaledHeight = Std.int(window.height * window.scale);

				gl.viewport (0, 0, scaledWidth, scaledHeight);

				var r = ((context.attributes.background >> 16) & 0xFF) / 0xFF;
				var g = ((context.attributes.background >> 8) & 0xFF) / 0xFF;
				var b = (context.attributes.background & 0xFF) / 0xFF;
				var a = ((context.attributes.background >> 24) & 0xFF) / 0xFF;

				gl.clearColor (r, g, b, a);
				gl.clear (gl.COLOR_BUFFER_BIT);

				if (image != null) {

					var matrix = new Matrix4 ();
					matrix.createOrtho (0, window.width, window.height, 0, -1000, 1000);
					gl.uniformMatrix4fv (glMatrixUniform, false, matrix);

					gl.activeTexture (gl.TEXTURE0);
					gl.bindTexture (gl.TEXTURE_2D, glTexture);

					#if desktop
					gl.enable (gl.TEXTURE_2D);
					#end

					gl.bindBuffer (gl.ARRAY_BUFFER, glBuffer);
					gl.vertexAttribPointer (glVertexAttribute, 3, gl.FLOAT, false, 5 * Float32Array.BYTES_PER_ELEMENT, 0);
					gl.vertexAttribPointer (glTextureAttribute, 2, gl.FLOAT, false, 5 * Float32Array.BYTES_PER_ELEMENT, 3 * Float32Array.BYTES_PER_ELEMENT);

					gl.drawArrays (gl.TRIANGLE_STRIP, 0, 4);

				}

			default:

		}

	}


}
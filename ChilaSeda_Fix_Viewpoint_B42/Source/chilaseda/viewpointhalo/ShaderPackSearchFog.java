/*
 * Decompiled with CFR 0.152.
 * Could not load the following classes:
 *  org.lwjgl.opengl.GL11
 *  org.lwjgl.opengl.GL13
 *  org.lwjgl.opengl.GL14
 *  org.lwjgl.opengl.GL20
 *  org.lwjgl.opengl.GL30
 *  org.lwjgl.opengl.GL33
 *  zombie.core.DefaultShader
 *  zombie.core.ShaderHelper
 *  zombie.core.SpriteRenderer
 *  zombie.core.opengl.GLStateRenderThread
 *  zombie.core.textures.Texture
 *  zombie.core.textures.TextureDraw$GenericDrawer
 */
package chilaseda.viewpointhalo;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.GL13;
import org.lwjgl.opengl.GL14;
import org.lwjgl.opengl.GL20;
import org.lwjgl.opengl.GL30;
import org.lwjgl.opengl.GL33;


import zombie.core.DefaultShader;
import zombie.core.ShaderHelper;
import zombie.core.SpriteRenderer;
import zombie.core.opengl.GLStateRenderThread;
import zombie.core.textures.Texture;
import zombie.core.textures.TextureDraw;

final class ShaderPackSearchFog
extends TextureDraw.GenericDrawer {
    private static final int GL_CURRENT_PROGRAM = 35725;
    private static final int GL_VERTEX_ARRAY_BINDING = 34229;
    private static final int GL_ACTIVE_TEXTURE = 34016;
    private static final int GL_ALL_ATTRIB_BITS = 1048575;
    private static final int GL_DEPTH_TEST = 2929;
    private static final int GL_CULL_FACE = 2884;
    private static final int GL_STENCIL_TEST = 2960;
    private static final int GL_SCISSOR_TEST = 3089;
    private static final int GL_BLEND = 3042;
    private static final int GL_FUNC_ADD = 32774;
    private static final int GL_SRC_ALPHA = 770;
    private static final int GL_ONE_MINUS_SRC_ALPHA = 771;
    private static final int GL_TEXTURE0 = 33984;
    private static final int GL_SAMPLER_BINDING = 35097;
    private static final int GL_TEXTURE_2D = 3553;
    private static final int GL_TRIANGLES = 4;
    private static final int GL_VERTEX_SHADER = 35633;
    private static final int GL_FRAGMENT_SHADER = 35632;
    private static final int GL_COMPILE_STATUS = 35713;
    private static final int GL_LINK_STATUS = 35714;
    private static final ShaderPackSearchFog INSTANCE = new ShaderPackSearchFog();
    private static volatile boolean failed;
    private static volatile String failure;
    private static boolean resolved;
    private static Field pipelineField;
    private static Field targetsField;
    private static Field uniformsField;
    private static Field depthField;
    private static Field projectionField;
    private static Method matrixGet;
    private static boolean resolvedNative;
    private static Field nativeTargets;
    private static Field nativeFrame;
    private static Field nativeDepth;
    private static Field nativeProj;
    static volatile long lastIrisDraw;
    static volatile long lastNativeDraw;
    private static boolean triedIrisFlag;
    private static Field irisFlag;
    private static int program;
    private static int vao;
    private static int uDepth;
    private static int uInvProj;
    private static int uRange;
    private static int uColor;
    private static int uPanini;
    private static int uPanTan;
    private static final float[] proj;
    private static final float[] panini = new float[5];
    private static final float[] inv;
    static volatile boolean enabled = true;
    private static final String VERT = "#version 330 core\nout vec2 vUv;\nvoid main() {\n  vec2 p = vec2(float((gl_VertexID << 1) & 2), float(gl_VertexID & 2));\n  vUv = p;\n  gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);\n}\n";
    private static final String FRAG = "#version 330 core\nin vec2 vUv;\nuniform sampler2D uDepth;\nuniform mat4 uInvProj;\nuniform vec2 uRange;\nuniform vec4 uColor;\nuniform vec3 uPanini;\nuniform vec2 uPanTan;\nvec2 toFrame(vec2 s) {\n  float d = uPanini.x;\n  if (d <= 0.0) return s;\n  vec2 P = s * uPanini.yz;\n  float t = P.x / (d + 1.0); float t2 = t * t;\n  float k = (sqrt(1.0 + t2 * (1.0 - d * d)) - t2 * d) / (1.0 + t2);\n  float S = (d + k) / ((d + 1.0) * k);\n  return P * S / uPanTan;\n}\nout vec4 fragColor;\nvoid main() {\n  vec2 f = toFrame(vUv * 2.0 - 1.0);\n  vec2 uv = f * 0.5 + 0.5;\n  ivec2 size = textureSize(uDepth, 0);\n  ivec2 px = clamp(ivec2(uv * vec2(size)), ivec2(0), size - 1);\n  float d = texelFetch(uDepth, px, 0).r;\n  float dist = 1.0e6;\n  if (d < 0.99999) {\n    vec4 v = uInvProj * vec4(f, d * 2.0 - 1.0, 1.0);\n    if (abs(v.w) > 1.0e-6) dist = length(v.xyz / v.w);\n  }\n  float fog = smoothstep(uRange.x, uRange.y, dist);\n  fragColor = vec4(uColor.rgb, fog * uColor.a);\n}\n";

    static boolean drawing() {
        long l = System.nanoTime();
        return l - lastIrisDraw < 300000000L || l - lastNativeDraw < 300000000L;
    }

    private static boolean irisThisFrame() {
        if (!triedIrisFlag) {
            triedIrisFlag = true;
            try {
                irisFlag = ShaderPackSearchFog.open(SearchFogBridge.viewpointClass("viewpoint.render.WorldRenderer"), "irisDrawn");
            }
            catch (Throwable throwable) {
                irisFlag = null;
            }
        }
        if (irisFlag != null) {
            try {
                return irisFlag.getBoolean(null);
            }
            catch (Throwable throwable) {
                // empty catch block
            }
        }
        return SearchFogBridge.shaderPackPresent();
    }

    private ShaderPackSearchFog() {
    }

    static boolean failed() {
        return failed;
    }

    static String failure() {
        return failure;
    }

    static boolean queue() {
        if (failed || !enabled) {
            return false;
        }
        if (SearchFogBridge.ownAlpha <= 0.001f) {
            return false;
        }
        try {
            SpriteRenderer.instance.drawGeneric((TextureDraw.GenericDrawer)INSTANCE);
            return true;
        }
        catch (Throwable throwable) {
            ShaderPackSearchFog.fail("queue", throwable);
            return false;
        }
    }

    private static void fail(String string, Throwable throwable) {
        failed = true;
        failure = string + ": " + String.valueOf(throwable);
        System.out.println("[ChilaSeda Viewpoint Fix] depth fog layer switched off (" + failure + ")");
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public void render() {
        int n;
        boolean bl;
        if (failed) {
            return;
        }
        float f = SearchFogBridge.ownAlpha;
        if (f <= 0.001f) {
            return;
        }
        try {
            Object object;
            Object rendererState;
            Object targets;
            bl = ShaderPackSearchFog.irisThisFrame();
            if (bl) {
                if (!ShaderPackSearchFog.resolve()) {
                    return;
                }
                rendererState = pipelineField.get(null);
                if (rendererState == null) {
                    return;
                }
                targets = targetsField.get(rendererState);
                Object uniforms = uniformsField.get(rendererState);
                if (targets == null || uniforms == null) {
                    return;
                }
                n = depthField.getInt(targets);
                object = projectionField.get(uniforms);
            } else {
                if (!ShaderPackSearchFog.resolveNative()) {
                    return;
                }
                targets = nativeTargets.get(null);
                Object frame = nativeFrame.get(null);
                if (targets == null || frame == null) {
                    return;
                }
                n = nativeDepth.getInt(targets);
                object = nativeProj.get(frame);
            }
            if (n <= 0 || object == null) {
                return;
            }
            matrixGet.invoke(object, new Object[]{proj});
            readPanini();
            if (!ShaderPackSearchFog.invert(proj, inv)) {
                return;
            }
        }
        catch (Throwable throwable) {
            ShaderPackSearchFog.fail("reading Viewpoint's shader pack frame", throwable);
            return;
        }
        boolean bl2 = DefaultShader.isActive;
        int n2 = Texture.lastTextureID;
        int n3 = GL11.glGetInteger((int)35725);
        int n4 = GL11.glGetInteger((int)34229);
        int n5 = GL11.glGetInteger((int)34016);
        GL11.glPushClientAttrib((int)-1);
        GL11.glPushAttrib((int)1048575);
        int n6 = 0;
        try {
            if (program == 0 && !ShaderPackSearchFog.build()) {
                return;
            }
            GL11.glDisable((int)2929);
            GL11.glDisable((int)2884);
            GL11.glDisable((int)2960);
            GL11.glDisable((int)3089);
            GL11.glDepthMask((boolean)false);
            GL11.glColorMask((boolean)true, (boolean)true, (boolean)true, (boolean)false);
            GL11.glEnable((int)3042);
            GL14.glBlendEquation((int)32774);
            GL11.glBlendFunc((int)770, (int)771);
            GL20.glUseProgram((int)program);
            GL13.glActiveTexture((int)33984);
            n6 = GL11.glGetInteger((int)35097);
            GL33.glBindSampler((int)0, (int)0);
            GL11.glBindTexture((int)3553, (int)n);
            GL20.glUniform1i((int)uDepth, (int)0);
            GL20.glUniformMatrix4fv((int)uInvProj, (boolean)false, (float[])inv);
            GL20.glUniform2f((int)uRange, (float)SearchFogBridge.ownStart, (float)SearchFogBridge.ownEnd);
            float f2 = panini[0];
            boolean bl3 = f2 > 0.0f && panini[1] > 0.0f && panini[2] > 0.0f;
            GL20.glUniform3f((int)uPanini, (float)(bl3 ? f2 : 0.0f), (float)panini[3], (float)panini[4]);
            GL20.glUniform2f((int)uPanTan, (float)(bl3 ? panini[1] : 1.0f), (float)(bl3 ? panini[2] : 1.0f));
            GL20.glUniform4f((int)uColor, (float)SearchFogBridge.ownR, (float)SearchFogBridge.ownG, (float)SearchFogBridge.ownB, (float)Math.min(1.0f, f));
            GL30.glBindVertexArray((int)vao);
            GL11.glDrawArrays((int)4, (int)0, (int)3);
            if (bl) {
                lastIrisDraw = System.nanoTime();
            } else {
                lastNativeDraw = System.nanoTime();
            }
        }
        catch (Throwable throwable) {
            ShaderPackSearchFog.fail("drawing", throwable);
        }
        finally {
            try {
                GL30.glBindVertexArray((int)n4);
                GL33.glBindSampler((int)0, (int)n6);
            }
            catch (Throwable throwable) {}
            GL11.glPopAttrib();
            GL11.glPopClientAttrib();
            GL20.glUseProgram((int)n3);
            ShaderHelper.forgetCurrentlyBound();
            DefaultShader.isActive = bl2;
            Texture.lastTextureID = n2;
            GL13.glActiveTexture((int)n5);
            SpriteRenderer.ringBuffer.restoreVbos = true;
            SpriteRenderer.ringBuffer.restoreBoundTextures = true;
            GLStateRenderThread.restore();
        }
    }

    private static void readPanini() {
        try {
            Class<?> renderer = SearchFogBridge.viewpointClass("viewpoint.render.WorldRenderer");
            Field frameField = open(renderer, "frame");
            Object frame = frameField.get(null);
            if (frame == null) return;
            Field pField = open(frame.getClass(), "panini");
            Object p = pField.get(frame);
            if (p == null) return;
            panini[0] = (float) open(p.getClass(), "d").getDouble(p);
            panini[1] = (float) open(p.getClass(), "tanX").getDouble(p);
            panini[2] = (float) open(p.getClass(), "tanY").getDouble(p);
            panini[3] = (float) open(p.getClass(), "halfX").getDouble(p);
            panini[4] = (float) open(p.getClass(), "halfY").getDouble(p);
        } catch (Throwable ignored) {
            java.util.Arrays.fill(panini, 0.0f);
        }
    }

    private static boolean resolve() throws Exception {
        if (resolved) {
            return pipelineField != null;
        }
        resolved = true;
        Class<?> clazz = SearchFogBridge.viewpointClass("viewpoint.render.IrisMode");
        pipelineField = ShaderPackSearchFog.open(clazz, "pipeline");
        Class<?> clazz2 = pipelineField.getType();
        targetsField = ShaderPackSearchFog.open(clazz2, "targets");
        uniformsField = ShaderPackSearchFog.open(clazz2, "uniforms");
        depthField = ShaderPackSearchFog.open(targetsField.getType(), "depth");
        projectionField = ShaderPackSearchFog.open(uniformsField.getType(), "projection");
        matrixGet = projectionField.getType().getMethod("get", float[].class);
        return true;
    }

    private static boolean resolveNative() throws Exception {
        if (resolvedNative) {
            return nativeTargets != null;
        }
        resolvedNative = true;
        Class<?> clazz = SearchFogBridge.viewpointClass("viewpoint.render.WorldRenderer");
        nativeTargets = ShaderPackSearchFog.open(clazz, "targets");
        nativeFrame = ShaderPackSearchFog.open(clazz, "frame");
        nativeDepth = nativeTargets.getType().getField("depth");
        nativeProj = nativeFrame.getType().getField("jitteredProjection");
        if (matrixGet == null) {
            matrixGet = nativeProj.getType().getMethod("get", float[].class);
        }
        return true;
    }

    private static Field open(Class<?> clazz, String string) throws NoSuchFieldException {
        Field field = clazz.getDeclaredField(string);
        field.setAccessible(true);
        return field;
    }

    private static boolean build() {
        int n = ShaderPackSearchFog.shader(35633, VERT);
        int n2 = ShaderPackSearchFog.shader(35632, FRAG);
        if (n == 0 || n2 == 0) {
            return false;
        }
        int n3 = GL20.glCreateProgram();
        GL20.glAttachShader((int)n3, (int)n);
        GL20.glAttachShader((int)n3, (int)n2);
        GL20.glLinkProgram((int)n3);
        GL20.glDeleteShader((int)n);
        GL20.glDeleteShader((int)n2);
        if (GL20.glGetProgrami((int)n3, (int)35714) == 0) {
            ShaderPackSearchFog.fail("linking the fog shader", new RuntimeException(GL20.glGetProgramInfoLog((int)n3)));
            return false;
        }
        uDepth = GL20.glGetUniformLocation((int)n3, (CharSequence)"uDepth");
        uInvProj = GL20.glGetUniformLocation((int)n3, (CharSequence)"uInvProj");
        uRange = GL20.glGetUniformLocation((int)n3, (CharSequence)"uRange");
        uColor = GL20.glGetUniformLocation((int)n3, (CharSequence)"uColor");
        uPanini = GL20.glGetUniformLocation((int)n3, (CharSequence)"uPanini");
        uPanTan = GL20.glGetUniformLocation((int)n3, (CharSequence)"uPanTan");
        vao = GL30.glGenVertexArrays();
        program = n3;
        return true;
    }

    private static int shader(int n, String string) {
        int n2 = GL20.glCreateShader((int)n);
        GL20.glShaderSource((int)n2, (CharSequence)string);
        GL20.glCompileShader((int)n2);
        if (GL20.glGetShaderi((int)n2, (int)35713) == 0) {
            ShaderPackSearchFog.fail("compiling the fog shader", new RuntimeException(GL20.glGetShaderInfoLog((int)n2)));
            GL20.glDeleteShader((int)n2);
            return 0;
        }
        return n2;
    }

    static boolean invert(float[] fArray, float[] fArray2) {
        float f = fArray[0];
        float f2 = fArray[5];
        float f3 = fArray[1];
        float f4 = fArray[4];
        float f5 = f * f2 - f3 * f4;
        float f6 = fArray[10];
        float f7 = fArray[15];
        float f8 = fArray[11];
        float f9 = fArray[14];
        float f10 = f6 * f7 - f8 * f9;
        float f11 = fArray[6];
        float f12 = fArray[2];
        float f13 = f * f11 - f12 * f4;
        float f14 = fArray[9];
        float f15 = fArray[13];
        float f16 = f14 * f7 - f8 * f15;
        float f17 = fArray[7];
        float f18 = fArray[3];
        float f19 = f * f17 - f18 * f4;
        float f20 = f14 * f9 - f6 * f15;
        float f21 = f3 * f11 - f12 * f2;
        float f22 = fArray[8];
        float f23 = fArray[12];
        float f24 = f22 * f7 - f8 * f23;
        float f25 = f3 * f17 - f18 * f2;
        float f26 = f22 * f9 - f6 * f23;
        float f27 = f12 * f17 - f18 * f11;
        float f28 = f22 * f15 - f14 * f23;
        float f29 = f5 * f10 - f13 * f16 + f19 * f20 + f21 * f24 - f25 * f26 + f27 * f28;
        if (!(Math.abs(f29) > 1.0E-20f)) {
            return false;
        }
        float f30 = 1.0f / f29;
        fArray2[0] = (f2 * f10 - f11 * f16 + f17 * f20) * f30;
        fArray2[1] = (f12 * f16 - f3 * f10 - f18 * f20) * f30;
        fArray2[2] = (f15 * f27 - f9 * f25 + f7 * f21) * f30;
        fArray2[3] = (f6 * f25 - f14 * f27 - f8 * f21) * f30;
        fArray2[4] = (f11 * f24 - f4 * f10 - f17 * f26) * f30;
        fArray2[5] = (f * f10 - f12 * f24 + f18 * f26) * f30;
        fArray2[6] = (f9 * f19 - f23 * f27 - f7 * f13) * f30;
        fArray2[7] = (f22 * f27 - f6 * f19 + f8 * f13) * f30;
        fArray2[8] = (f4 * f16 - f2 * f24 + f17 * f28) * f30;
        fArray2[9] = (f3 * f24 - f * f16 - f18 * f28) * f30;
        fArray2[10] = (f23 * f25 - f15 * f19 + f7 * f5) * f30;
        fArray2[11] = (f14 * f19 - f22 * f25 - f8 * f5) * f30;
        fArray2[12] = (f2 * f26 - f4 * f20 - f11 * f28) * f30;
        fArray2[13] = (f * f20 - f3 * f26 + f12 * f28) * f30;
        fArray2[14] = (f15 * f13 - f23 * f21 - f9 * f5) * f30;
        fArray2[15] = (f22 * f21 - f14 * f13 + f6 * f5) * f30;
        return true;
    }

    static {
        proj = new float[16];
        inv = new float[16];
        enabled = true;
    }
}

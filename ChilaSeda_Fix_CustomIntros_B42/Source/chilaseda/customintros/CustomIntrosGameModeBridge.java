package chilaseda.customintros;

import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.nio.file.Path;
import java.util.List;
import java.util.Random;
import java.util.Set;
import java.util.function.Supplier;

import me.zed_0xff.zombie_buddy.Patch;

/** Replays Custom Intros' loading setup while using the current Core game-mode API. */
@Patch(className = "pzcustomintros.Boot", methodName = "beginLoading", warmUp = true)
public final class CustomIntrosGameModeBridge {
    @Patch.OnEnter(skipOn = true)
    public static boolean beginLoading() {
        return runBridge();
    }

    /** Public because ZombieBuddy inlines the advice into pzcustomintros.Boot. */
    public static boolean runBridge() {
        ClassLoader loader = CustomIntrosGameModeBridge.class.getClassLoader();
        Class<?> boot = null;
        try {
            boot = Class.forName("pzcustomintros.Boot", true, loader);
            invoke(boot, "endLoading", new Class<?>[0], null);

            Class<?> coreClass = Class.forName("zombie.core.Core", true, loader);
            Object core = coreClass.getMethod("getInstance").invoke(null);
            Object gameMode = coreClass.getMethod("getGameMode").invoke(core);
            if (gameMode != null && "Tutorial".equals(gameMode.toString())) return true;

            Class<?> choice = Class.forName("pzcustomintros.Choice", true, loader);
            Path options = (Path) invoke(boot, "optionsFile", new Class<?>[0], null);
            Object selected = invoke(choice, "readLoading", new Class<?>[] { Path.class }, null, options);
            @SuppressWarnings("unchecked")
            Set<Object> pool = (Set<Object>) invoke(choice, "pool", new Class<?>[] { Path.class }, null, options);
            Class<?> styleClass = Class.forName("pzcustomintros.Style", true, loader);
            Object style = invoke(styleClass, "resolve",
                    new Class<?>[] { Random.class, Set.class }, selected, new Random(), pool);

            Class<?> storyClass = Class.forName("pzcustomintros.Story", true, loader);
            Supplier<Object> details = () -> {
                try {
                    return invoke(bootClass(loader), "details", new Class<?>[0], null);
                } catch (Throwable error) {
                    throw new IllegalStateException(error);
                }
            };
            Constructor<?> storyConstructor = storyClass.getDeclaredConstructor(Supplier.class, boolean.class);
            storyConstructor.setAccessible(true);
            Object story = storyConstructor.newInstance(details, false);
            Object intro = invoke(styleClass, "loading", new Class<?>[] { storyClass }, style, story);
            if (intro == null) return true;

            Class<?> introClass = Class.forName("pzcustomintros.Intro", true, loader);
            @SuppressWarnings("unchecked")
            Set<Object> uses = (Set<Object>) invoke(introClass, "uses", new Class<?>[0], intro);
            @SuppressWarnings("unchecked")
            List<String> pictures = (List<String>) invoke(introClass, "pictures", new Class<?>[0], intro);

            Class<?> canvasClass = Class.forName("pzcustomintros.GameCanvas", true, loader);
            Object canvas = getStatic(canvasClass, "INSTANCE");
            invoke(canvasClass, "release", new Class<?>[0], canvas);
            invoke(canvasClass, "load", new Class<?>[] { Set.class, List.class }, canvas, uses, pictures);

            setStatic(boot, "story", story);
            setStatic(boot, "waiting", intro);
            Class<?> gateClass = Class.forName("pzcustomintros.Gate", true, loader);
            Object gate = invoke(gateClass, "forPictures",
                    new Class<?>[] { List.class, int.class, float.class }, null, pictures, 15, 8.0f);
            setStatic(boot, "loadingGate", gate);

            Class<?> soundClass = Class.forName("zombie.SoundManager", true, loader);
            Object soundManager = getStatic(soundClass, "instance");
            invoke(soundClass, "setMusicState", new Class<?>[] { String.class }, soundManager, "MainMenu");
            setStatic(boot, "songHeld", true);
        } catch (Throwable error) {
            Throwable cause = unwrap(error);
            try {
                if (boot == null) boot = Class.forName("pzcustomintros.Boot", true, loader);
                invoke(boot, "failLoading", new Class<?>[] { String.class, Throwable.class }, null,
                        "picking the loading intro", cause);
            } catch (Throwable fallbackError) {
                System.out.println("[ChilaSeda Custom Intros] Loading intro bridge failed: " + cause);
                fallbackError.printStackTrace(System.out);
            }
        }
        return true;
    }

    private static Class<?> bootClass(ClassLoader loader) throws ClassNotFoundException {
        return Class.forName("pzcustomintros.Boot", true, loader);
    }

    private static Object invoke(Class<?> type, String name, Class<?>[] signature, Object target, Object... args)
            throws ReflectiveOperationException {
        Method method = type.getDeclaredMethod(name, signature);
        method.setAccessible(true);
        return method.invoke(target, args);
    }

    private static Object getStatic(Class<?> type, String name) throws ReflectiveOperationException {
        Field field = type.getDeclaredField(name);
        field.setAccessible(true);
        return field.get(null);
    }

    private static void setStatic(Class<?> type, String name, Object value) throws ReflectiveOperationException {
        Field field = type.getDeclaredField(name);
        field.setAccessible(true);
        field.set(null, value);
    }

    private static Throwable unwrap(Throwable error) {
        return error instanceof InvocationTargetException && error.getCause() != null
                ? error.getCause() : error;
    }

    private CustomIntrosGameModeBridge() { }
}

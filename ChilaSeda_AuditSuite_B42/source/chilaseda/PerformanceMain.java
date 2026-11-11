package chilaseda;
import me.zed_0xff.zombie_buddy.Exposer;
import java.lang.management.*;
import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.*;
import java.io.*;

@Exposer.LuaClass(name="ChilaPerfJ")
public final class PerformanceMain {
 static final long PRE=8_000_000_000L, POST=4_000_000_000L, MAX=20_000_000_000L;
 static final int CAP=4096;
 static final ArrayDeque<Row> ring=new ArrayDeque<>();
 static final ThreadMXBean threads=ManagementFactory.getThreadMXBean();
 static final List<GarbageCollectorMXBean> collectors=ManagementFactory.getGarbageCollectorMXBeans();
 static final ThreadPoolExecutor writer=new ThreadPoolExecutor(1,1,0,TimeUnit.SECONDS,new ArrayBlockingQueue<Runnable>(4),r->{Thread t=new Thread(r,"ChilaPerf-writer");t.setDaemon(true);return t;},new ThreadPoolExecutor.AbortPolicy());
 static long renderLast=0, renderCount=0; static double renderMax=Double.NaN;
 public static synchronized void renderPulse(){long n=System.nanoTime(); if(renderLast!=0){double d=(n-renderLast)/1e6;renderMax=Double.isNaN(renderMax)?d:Math.max(renderMax,d);}renderLast=n;renderCount++;}
 static long chunkCallbacks=0, markerDropped=0; static ArrayList<String> markers=new ArrayList<>();
 public static synchronized void chunkLoaded(){chunkCallbacks++;}
 public static synchronized void mark(String message){if(markers.size()<64)markers.add("MARK mono_ns="+System.nanoTime()+" "+safe(message));else markerDropped++;}
 public static String startGame() throws Exception {
  Class<?> fs=Class.forName("zombie.ZomboidFileSystem");
  Object instance=fs.getField("instance").get(null);
  return start((String)fs.getMethod("getCacheDir").invoke(instance));
 }
 static Path path; static long last=0,lastCpu=-1,lastGc=0,gcCount=-1,gcMs=-1,coolUntil=0,seq=0,total=0,overhead=0,worst=0;
 static String session=UUID.randomUUID().toString(),context="UNAVAILABLE:no_Lua_context";
 static long lastTestRequest=Long.MIN_VALUE; static Event active; static boolean requestTest=false; static volatile String result="NOT_RUN"; static int dropped=0;
 static class Row {
  long t,used,free,max,gcc,gcm,gcage,previous,rc,chunks,droppedMarkers; List<String> marks; double gap,cpu,render; String ctx;
  String line(){return "SAMPLE mono_ns="+t+" tick_gap_ms="+(Double.isNaN(gap)?"UNAVAILABLE:first_sample":gap)+" render_callback_gap_max_ms="+(Double.isNaN(render)?"UNAVAILABLE:no_render_pulse_interval":render)+" render_callback_count="+rc+" frame_ms=UNAVAILABLE:no_present_hook main_thread_cpu_delta_ms="+(Double.isNaN(cpu)?"UNAVAILABLE:thread_cpu_disabled_or_first_sample":cpu)+" render_thread_ms=UNAVAILABLE:no_hook heap_used_bytes="+used+" heap_free_committed_bytes="+free+" heap_max_bytes="+max+" gc_count="+(gcc<0?"UNAVAILABLE":gcc)+" gc_ms="+(gcm<0?"UNAVAILABLE":gcm)+" gc_age_ms="+gcage/1e6+" previous_probe_java_ns="+previous+" loadchunk_callbacks_total="+chunks+" dropped_markers_total="+droppedMarkers;}
 }
 static class Event {String id; boolean test; long trigger,end; double peak; int spikes; ArrayList<Row> rows=new ArrayList<>();}
 static String safe(String s){return s==null?"UNAVAILABLE":s.replace('\n',' ').replace('\r',' ').replace('\t',' ');}
 public static synchronized String start(String cacheDir){
  if(path!=null)return path.toString();
  if(cacheDir==null||cacheDir.isBlank())throw new IllegalArgumentException("cache directory unavailable");
  path=Paths.get(cacheDir).toAbsolutePath().normalize().resolve("ChilaPerformance.log");
  System.out.println("[ChilaPerf] JAVA_EXECUTING log="+path+" tick-gap observer; frame/render timings UNAVAILABLE");
  Runtime.getRuntime().addShutdownHook(new Thread(()->{flush();writer.shutdown();try{writer.awaitTermination(3,TimeUnit.SECONDS);}catch(InterruptedException ignored){Thread.currentThread().interrupt();}},"ChilaPerf-shutdown"));
  return path.toString();
 }
 public static synchronized void context(String value){context=safe(value);}
 public static synchronized String selftest(){
  if(requestTest||(active!=null&&active.test))return result;
  long n=System.nanoTime();if(lastTestRequest!=Long.MIN_VALUE&&n-lastTestRequest<60_000_000_000L)return "THROTTLED:selftest_once_per_60s";
  lastTestRequest=n;requestTest=true;result="PENDING:needs_8s_buffer_then_4s_post";return result;
 }
 public static double monotonicMs(){return System.nanoTime()/1e6;}
 public static String selftestResult(){return result;}
 public static String severity(double ms){return ms>250?"CRITICAL_250":ms>100?"HIGH_100":ms>50?"MEDIUM_50":ms>33?"LOW_33":"NORMAL";}
 public static synchronized void tick(){
  if(path==null)return;
  long begin=System.nanoTime(), now=begin;
  double gap=last==0?Double.NaN:(now-last)/1e6; last=now;
  long cpu=threads.isCurrentThreadCpuTimeSupported()&&threads.isThreadCpuTimeEnabled()?threads.getCurrentThreadCpuTime():-1;
  double cpuDelta=cpu>=0&&lastCpu>=0?(cpu-lastCpu)/1e6:Double.NaN;lastCpu=cpu;
  if(now-lastGc>=250_000_000L){long c=0,m=0;boolean ok=true;for(GarbageCollectorMXBean g:collectors){long a=g.getCollectionCount(),b=g.getCollectionTime();if(a<0||b<0){ok=false;break;}c+=a;m+=b;}gcCount=ok?c:-1;gcMs=ok?m:-1;lastGc=now;}
  Runtime rt=Runtime.getRuntime();
  double observed=Double.isNaN(renderMax)?gap:Math.max(Double.isNaN(gap)?0:gap,renderMax);
  Row row=new Row();row.marks=markers;markers=new ArrayList<>();row.chunks=chunkCallbacks;row.droppedMarkers=markerDropped;row.t=now;row.ctx=context;row.gap=gap;row.cpu=cpuDelta;row.render=renderMax;renderMax=Double.NaN;row.rc=renderCount;row.used=rt.totalMemory()-rt.freeMemory();row.free=rt.freeMemory();row.max=rt.maxMemory();row.gcc=gcCount;row.gcm=gcMs;row.gcage=now-lastGc;row.previous=overhead;
  total++;ring.addLast(row);while(ring.size()>CAP||(!ring.isEmpty()&&now-ring.peekFirst().t>PRE))ring.removeFirst();
  boolean test=requestTest&&ring.size()>1&&now-ring.peekFirst().t>=PRE-100_000_000L;
  boolean spike=observed>33;
  if(active==null&&(test||(spike&&now>=coolUntil))){
   active=new Event();active.id="SPIKE-"+(++seq<10?"000":seq<100?"00":seq<1000?"0":"")+seq;active.test=test;active.trigger=now;active.end=now+POST;active.peak=Double.isNaN(observed)?0:observed;active.rows.addAll(ring);active.spikes=spike?1:0;
   if(test)requestTest=false;
  }else if(active!=null){active.rows.add(row);if(spike){active.spikes++;active.peak=Math.max(active.peak,observed);active.end=Math.min(active.trigger+MAX,now+POST);}}
  if(active!=null&&(now>=active.end||active.rows.size()>=8192))finish(now,"post_window_or_cap");
  overhead=System.nanoTime()-begin;worst=Math.max(worst,overhead);
 }
 static void finish(long now,String reason){Event e=active;active=null;coolUntil=now+15_000_000_000L;
  try{writer.execute(()->persist(e,reason));}catch(RejectedExecutionException x){dropped++;if(e.test)result="FAIL:writer_queue_full";System.out.println("[ChilaPerf] ERROR writer_queue_full dropped="+dropped);}
 }
 static void persist(Event e,String reason){
  try{
   String prefix="[ChilaPerf]["+e.id+"]";
   StringBuilder b=new StringBuilder(prefix+" BEGIN session="+session+" utc="+java.time.Instant.now()+" synthetic="+e.test+" severity="+severity(e.peak)+" peak_callback_gap_ms="+e.peak+" trigger_ns="+e.trigger+" pre_actual_ms="+((e.trigger-e.rows.get(0).t)/1e6)+" post_actual_ms="+((e.rows.get(e.rows.size()-1).t-e.trigger)/1e6)+" samples="+e.rows.size()+" reason="+reason+"\n");
   b.append("METRICS zombie_update_ms=UNAVAILABLE:no_instrumentation render_frame_ms=UNAVAILABLE:no_render_hook asset_model_texture_animation_loading=UNAVAILABLE:no_verified_hooks chunk_load_duration=UNAVAILABLE:no_verified_hook callbacks_java_lua_duration=UNAVAILABLE:not_instrumented ai_state_change=event_observer_if_called chunk_load=count_only_no_duration gc=process_cumulative_polled_250ms\n");
   String previous=null;for(Row r:e.rows){if(r.ctx!=previous){b.append("CONTEXT captured_at_or_before_sample_ns=").append(r.t).append(" ").append(r.ctx).append('\n');previous=r.ctx;}b.append(r.line()).append('\n');for(String mark:r.marks)b.append(mark).append('\n');}
   b.append(prefix).append(" END\n");
   byte[] bytes=b.toString().getBytes(StandardCharsets.UTF_8);
   Files.createDirectories(path.getParent());
   if(Files.exists(path)&&Files.size(path)+bytes.length>20L*1024*1024){for(int i=3;i>=1;i--){Path dst=Paths.get(path+"."+i);Path src=i==1?path:Paths.get(path+"."+(i-1));if(Files.exists(src))Files.move(src,dst,StandardCopyOption.REPLACE_EXISTING);}}
   long offset;
   try(RandomAccessFile f=new RandomAccessFile(path.toFile(),"rw")){offset=f.length();f.seek(offset);f.write(bytes);f.getFD().sync();
    if(e.test){f.seek(offset);byte[] read=new byte[bytes.length];f.readFully(read);if(!Arrays.equals(bytes,read)||e.rows.size()<2||e.trigger-e.rows.get(0).t<7_800_000_000L||e.rows.get(e.rows.size()-1).t-e.trigger<3_900_000_000L)throw new IOException("selftest pipeline verification failed");
     for(int i=0;i<e.rows.size();i++){Row r=e.rows.get(i);if(r.used<=0||r.max<=0||(i>0&&r.t<=e.rows.get(i-1).t))throw new IOException("invalid runtime samples");}
     String pass="[ChilaPerf][SELFTEST] PASS session="+session+" event="+e.id+" verified_bytes="+bytes.length+" samples="+e.rows.size()+" capture=buffered_runtime_samples trigger=artificial persistence=readback_equal\n";
     f.seek(f.length());f.write(pass.getBytes(StandardCharsets.UTF_8));f.getFD().sync();result=pass.trim();System.out.println(result);
    }
   }
   System.out.println(prefix+" SAVED synthetic="+e.test+" peak_callback_gap_ms="+e.peak+" samples="+e.rows.size()+" log="+path);
  }catch(Exception x){if(e.test)result="FAIL:"+x;System.out.println("[ChilaPerf] ERROR persistence "+x);}
 }
 public static synchronized String status(){return "samples="+total+" buffered="+ring.size()+" writer_queue="+writer.getQueue().size()+" dropped="+dropped+" previous_java_ns="+overhead+" worst_java_ns="+worst+" log="+path+" selftest="+result;}
 public static synchronized void flush(){if(active!=null)finish(System.nanoTime(),"manual_flush_incomplete_window");}
}

import chilaseda.PerformanceMain;
import java.nio.file.*;
import java.util.*;
public class Harness {
 public static void main(String[] args)throws Exception{
  PerformanceMain.start(args[0]);PerformanceMain.context("player_xyz=UNAVAILABLE:standalone_JVM_no_PZ zombies=UNAVAILABLE:standalone_JVM_no_PZ fixture=real_JVM_clock_heap_GC_not_game");
  if(!PerformanceMain.severity(34).equals("LOW_33")||!PerformanceMain.severity(51).equals("MEDIUM_50")||!PerformanceMain.severity(101).equals("HIGH_100")||!PerformanceMain.severity(251).equals("CRITICAL_250"))throw new AssertionError("thresholds");
  PerformanceMain.selftest();long until=System.nanoTime()+15_000_000_000L;ArrayList<Long> cost=new ArrayList<>();
  while(System.nanoTime()<until){PerformanceMain.renderPulse();long a=System.nanoTime();PerformanceMain.tick();cost.add(System.nanoTime()-a);Thread.sleep(16);}
  long wait=System.nanoTime()+5_000_000_000L;while(!PerformanceMain.selftestResult().contains("PASS")&&System.nanoTime()<wait)Thread.sleep(10);
  if(!PerformanceMain.selftestResult().contains("PASS"))throw new AssertionError(PerformanceMain.status());
  Collections.sort(cost);System.out.println("MEASURED standalone_JVM tick_calls="+cost.size()+" p50_us="+cost.get(cost.size()/2)/1000.0+" p99_us="+cost.get((int)(cost.size()*.99))/1000.0+" max_us="+cost.get(cost.size()-1)/1000.0);
  System.out.println(PerformanceMain.status());
 }
}

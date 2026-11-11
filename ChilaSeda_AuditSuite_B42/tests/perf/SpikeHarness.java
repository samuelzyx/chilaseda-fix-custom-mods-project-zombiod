import chilaseda.PerformanceMain;
public class SpikeHarness {
 public static void main(String[] args)throws Exception{
  PerformanceMain.start(args[0]);PerformanceMain.context("player_xyz=UNAVAILABLE:standalone_JVM controlled_test=stall_270ms_NOT_in_game");
  long begin=System.nanoTime();boolean stalled=false;
  while(System.nanoTime()-begin<14_000_000_000L){
   if(!stalled&&System.nanoTime()-begin>8_500_000_000L){PerformanceMain.mark("HARNESS_CONTROLLED_STALL requested_ms=270");PerformanceMain.chunkLoaded();Thread.sleep(270);stalled=true;}
   PerformanceMain.renderPulse();PerformanceMain.tick();Thread.sleep(16);
  }
  System.out.println(PerformanceMain.status());
 }
}

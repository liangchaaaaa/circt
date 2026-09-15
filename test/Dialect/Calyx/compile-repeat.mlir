// RUN: circt-opt -pass-pipeline='builtin.module(calyx.component(calyx-compile-repeat))' --split-input-file %s | FileCheck %s --implicit-check-not="calyx.repeat"

// CHECK-LABEL: calyx.component @main(
module attributes {calyx.entrypoint = "main"} {
  calyx.component @main(%go: i1 {go}, %clk: i1 {clk}, %reset: i1 {reset}) -> (%done: i1 {done}) {
    %c1 = hw.constant true
    %r.in, %r.write_en, %r.clk, %r.reset, %r.out, %r.done = calyx.register @r : i1, i1, i1, i1, i1, i1
    calyx.wires {
      calyx.group @B {
        calyx.assign %r.in = %c1 : i1
        calyx.assign %r.write_en = %c1 : i1
        calyx.group_done %r.done : i1
      }
    }
    calyx.control {
      calyx.seq {
        calyx.repeat 4 {
          calyx.seq {
            calyx.enable @B
          }
        }
      }
    }
  }
}

// CHECK: calyx.std_add @repeat_add : i3, i3, i3
// CHECK: calyx.std_lt @repeat_lt : i3, i3, i1
// CHECK: calyx.register @repeat_cond_reg
// CHECK: calyx.register @repeat_counter_reg
// CHECK: calyx.group @repeat_init
// CHECK: calyx.group @repeat_incr
// CHECK: calyx.group @repeat_cond
// CHECK: calyx.enable @repeat_init
// CHECK: calyx.enable @repeat_cond
// CHECK: calyx.while %repeat_cond_reg.out {
// CHECK: calyx.enable @B
// CHECK: calyx.enable @repeat_incr
// CHECK: calyx.enable @repeat_cond

// -----

// A repeat that is the only operation in `calyx.control`.

// CHECK-LABEL: calyx.component @one(
module attributes {calyx.entrypoint = "one"} {
  calyx.component @one(%go: i1 {go}, %clk: i1 {clk}, %reset: i1 {reset}) -> (%done: i1 {done}) {
    %c1 = hw.constant true
    %r.in, %r.write_en, %r.clk, %r.reset, %r.out, %r.done = calyx.register @r : i1, i1, i1, i1, i1, i1
    calyx.wires {
      calyx.group @B {
        calyx.assign %r.in = %c1 : i1
        calyx.assign %r.write_en = %c1 : i1
        calyx.group_done %r.done : i1
      }
    }
    calyx.control {
      calyx.repeat 1 {
        calyx.enable @B
      }
    }
  }
}

// A single-trip repeat uses a 1-bit counter.
// CHECK: calyx.register @repeat_counter_reg
// CHECK: calyx.enable @repeat_init
// CHECK: calyx.enable @repeat_cond
// CHECK: calyx.while %repeat_cond_reg.out {
// CHECK: calyx.enable @repeat_incr
// CHECK: calyx.enable @repeat_cond

// -----

// A zero-trip repeat disappears entirely.

// CHECK-LABEL: calyx.component @zero(
module attributes {calyx.entrypoint = "zero"} {
  calyx.component @zero(%go: i1 {go}, %clk: i1 {clk}, %reset: i1 {reset}) -> (%done: i1 {done}) {
    %c1 = hw.constant true
    %r.in, %r.write_en, %r.clk, %r.reset, %r.out, %r.done = calyx.register @r : i1, i1, i1, i1, i1, i1
    calyx.wires {
      calyx.group @B {
        calyx.assign %r.in = %c1 : i1
        calyx.assign %r.write_en = %c1 : i1
        calyx.group_done %r.done : i1
      }
    }
    calyx.control {
      calyx.seq {
        calyx.enable @B
        calyx.repeat 0 {
          calyx.enable @B
        }
      }
    }
  }
}

// CHECK-NOT: calyx.while
// CHECK-NOT: repeat_counter_reg

// -----

// Nested repeats each get their own counter and while loop.

// CHECK-LABEL: calyx.component @nested(
module attributes {calyx.entrypoint = "nested"} {
  calyx.component @nested(%go: i1 {go}, %clk: i1 {clk}, %reset: i1 {reset}) -> (%done: i1 {done}) {
    %c1 = hw.constant true
    %r.in, %r.write_en, %r.clk, %r.reset, %r.out, %r.done = calyx.register @r : i1, i1, i1, i1, i1, i1
    calyx.wires {
      calyx.group @B {
        calyx.assign %r.in = %c1 : i1
        calyx.assign %r.write_en = %c1 : i1
        calyx.group_done %r.done : i1
      }
    }
    calyx.control {
      calyx.repeat 2 {
        calyx.seq {
          calyx.enable @B
          calyx.repeat 3 {
            calyx.enable @B
          }
        }
      }
    }
  }
}

// The walk is post-ordered, so the inner repeat reserves `repeat_` and the
// outer one gets the `repeat_1_` prefix.
// CHECK: calyx.register @repeat_1_cond_reg
// CHECK: calyx.register @repeat_cond_reg
// CHECK: calyx.enable @repeat_1_init
// CHECK: calyx.enable @repeat_1_cond
// CHECK: calyx.while %repeat_1_cond_reg.out {
// CHECK: calyx.enable @B
// CHECK: calyx.enable @repeat_init
// CHECK: calyx.enable @repeat_cond
// CHECK: calyx.while %repeat_cond_reg.out {
// CHECK: calyx.enable @B
// CHECK: calyx.enable @repeat_incr
// CHECK: calyx.enable @repeat_cond
// CHECK: calyx.enable @repeat_1_incr
// CHECK: calyx.enable @repeat_1_cond

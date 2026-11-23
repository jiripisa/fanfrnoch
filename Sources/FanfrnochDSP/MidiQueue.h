// MidiQueue.h - MIDI events, and the queue that carries MIDI posted from any thread to the audio
// thread. Taken from Didgeridoo (DidgeridooEngine.cpp: MidiEvent, postMidi and its drain in
// process).

#pragma once

#include <atomic>
#include <cstdint>

namespace fanfrnoch {

struct MidiEvent
{
    int sampleOffset;
    uint8_t status, data1, data2;

    uint8_t kind() const { return status & 0xF0; }
    bool isNoteOn() const { return kind() == 0x90 && data2 != 0; }
    bool isNoteOff() const { return kind() == 0x80 || (kind() == 0x90 && data2 == 0); }
    bool isController() const { return kind() == 0xB0; }
    bool isPitchBend() const { return kind() == 0xE0; }
    bool isAftertouch() const { return kind() == 0xD0; }
    bool isAllNotesOff() const { return isController() && (data1 == 123 || data1 == 120); }
    int  pitchBend() const { return (data1 | (data2 << 7)) - 8192; }
};

// Posted MIDI waits in a bounded queue that any number of threads fill and the audio thread
// empties, without a lock (Dmitry Vyukov's bounded queue). Queue positions count up for ever; a
// slot's `turn` says which position may use it next: equal to a writer's position when the slot
// is free for it, one more once the event is in.
class MidiQueue
{
public:
    MidiQueue()
    {
        for (uint32_t i = 0; i < kSize; ++i) slots_[i].turn.store(i, std::memory_order_relaxed);
    }

    void post(uint8_t status, uint8_t d1, uint8_t d2, int offset)   // any thread
    {
        uint32_t position = write_.load(std::memory_order_relaxed);
        for (;;)
        {
            Slot& slot = slots_[position % kSize];
            const int32_t ahead = (int32_t)(slot.turn.load(std::memory_order_acquire) - position);
            if (ahead == 0)                 // free for this position: claim it, then fill it
            {
                if (write_.compare_exchange_weak(position, position + 1, std::memory_order_relaxed))
                {
                    slot.event = MidiEvent{ offset < 0 ? 0 : offset, status, d1, d2 };
                    slot.turn.store(position + 1, std::memory_order_release);
                    return;
                }
            }
            else if (ahead < 0) return;     // still unread from a lap ago: the queue is full, the event is dropped
            else position = write_.load(std::memory_order_relaxed);   // another thread took this position
        }
    }

    // Hands the events that are in to `take`, in the order posted (audio thread), until `take`
    // returns false: that event stays in the queue, first for the next drain. Reading also stops
    // at the first slot whose event is not in yet, so the order is kept.
    template <class Take> void drain(Take&& take)
    {
        for (;;)
        {
            Slot& slot = slots_[read_ % kSize];
            if (slot.turn.load(std::memory_order_acquire) != read_ + 1) break;
            if (!take(slot.event)) break;
            slot.turn.store(read_ + kSize, std::memory_order_release);     // free for the next lap
            ++read_;
        }
    }

private:
    static constexpr uint32_t kSize = 512;    // a power of two: positions wrap around cleanly

    struct Slot { std::atomic<uint32_t> turn; MidiEvent event; };
    Slot slots_[kSize];
    std::atomic<uint32_t> write_{0};    // next position to write: shared by the posting threads
    uint32_t read_ = 0;                 // next position to read: the audio thread's own
};

} // namespace fanfrnoch

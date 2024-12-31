package ca.kam.devices.terminal

import ca.kam.vmhardwarelibraries.DeviceAsks
import ca.kam.vmhardwarelibraries.TechDevice
import ca.kam.vmhardwarelibraries.memory.MemoryDevice
import java.lang.Integer.min
import java.lang.Integer.toHexString

@OptIn(ExperimentalUnsignedTypes::class)
class TerminalDevice: TechDevice {
    val CODE = TerminalDevice::class.java.getResourceAsStream("/tdd.a")!!.readBytes().asUByteArray()

    lateinit var mBuffer: MemoryDevice

    override val isForked: Boolean = false

    var cRead: String? = null

    override fun deviceInfo(): DeviceAsks = DeviceAsks(
        0x7fu,
        CODE.size.toUShort(),
        50u,
        arrayOf(0x0004u)
    )

    override fun getCode(): UByteArray = CODE.copyOf()

    override fun lockBuffer(memory: MemoryDevice) {
        mBuffer = memory
    }

    override fun signal() {
        when (mBuffer.bit8[0u]) {
            0.toUByte() -> {
                if (cRead == null || cRead?.length == 0) {
                    cRead = readln()
                }
                val hasMore = cRead!!.length > 47
                mBuffer.bit8[0u] = if (hasMore) 1u else 0u
                mBuffer.bit16[1u] = cRead!!.length.toUShort()
                mBuffer.load(
                    cRead!!.take(47).toByteArray().toUByteArray(),
                    3u
                )
                cRead = if (hasMore) cRead!!.slice(47..cRead!!.length) else null
            }

            1.toUByte() -> {
                var i = 1
                var s: String = ""
                do {
                    val c = mBuffer.bit8[i.toUShort()].toInt().toChar()
                    s += c
                    i++
                } while (mBuffer.bit8[i.toUShort()] != 0.toUByte())
                print(s)
            }

            2.toUByte() -> {
                cRead = null
            }

            3.toUByte() -> {
                val length = mBuffer.bit16[1.toUShort()].toInt()
                var s: String = ""
                for (i in 3 until length) {
                    val c = mBuffer.bit8[i.toUShort()].toInt().toChar()
                    s += c
                }
                cRead = s + cRead
            }

            4.toUByte() -> {
                if (cRead == null) {
                    mBuffer.bit8[0u] = 0u
                    mBuffer.bit16[1u] = 0u
                } else {
                    mBuffer.bit8[0u] = if (cRead!!.length > 47) 1u else 0u
                    mBuffer.bit16[1u] = cRead!!.length.toUShort()
                    mBuffer.load(
                        cRead!!.take(47).toByteArray().toUByteArray(),
                        3u
                    )
                    cRead = cRead!!.drop(47)
                }
            }
        }
    }

//    companion object {
//        val CODE = ubyteArrayOf(
//            0x00u, 0x00u, 0x00u, 0x98u, 0x00u, 0x00u, 0x01u, 0x6au,
//            0x03u, 0x00u, 0x47u, 0x98u, 0x00u, 0x00u, 0x09u, 0x9au,
//            0x00u, 0x01u, 0x08u, 0x47u, 0x01u, 0xbfu, 0x02u, 0x07u,
//            0xbbu, 0x07u, 0x08u, 0x47u, 0x00u, 0x30u, 0x08u, 0x30u,
//            0x09u, 0x31u, 0x03u, 0x30u, 0x02u, 0x98u, 0x00u, 0x00u,
//            0x01u, 0x6au, 0x03u, 0x00u, 0x35u, 0x98u, 0x00u, 0x31u,
//            0x01u, 0x6du, 0x09u, 0x00u, 0x13u, 0x98u, 0x00u, 0x00u,
//            0x08u, 0x9bu, 0x00u, 0x00u, 0x09u, 0x27u, 0x09u, 0x98u,
//            0x00u, 0x00u, 0x01u, 0x6du, 0x03u, 0x00u, 0x03u, 0x05u,
//            0x9au, 0x00u, 0x01u, 0x09u, 0x98u, 0x00u, 0xf0u, 0x08u,
//            0x47u, 0x01u, 0xbau, 0x08u, 0x09u, 0x47u, 0x00u, 0x9au,
//            0x00u, 0x00u, 0x08u, 0x27u, 0x08u, 0x47u, 0x01u, 0xbfu,
//            0x09u, 0x07u, 0x47u, 0x00u, 0x77u, 0x07u, 0x00u, 0x80u,
//            0xb8u, 0x01u, 0x06u, 0xb1u, 0x06u, 0x07u, 0xb8u, 0x01u,
//            0x07u, 0x98u, 0x00u, 0x00u, 0x01u, 0x6au, 0x07u, 0x00u,
//            0x99u, 0x30u, 0x09u, 0x47u, 0x01u, 0xbfu, 0x09u, 0x05u,
//            0xbbu, 0x05u, 0x02u, 0x47u, 0x00u, 0x30u, 0x02u, 0x30u,
//            0x09u, 0x31u, 0x07u, 0x31u, 0x03u, 0x98u, 0x00u, 0x00u,
//            0x01u, 0x6au, 0x03u, 0x00u, 0x99u, 0x6du, 0x07u, 0x00u,
//            0x7bu, 0x98u, 0x00u, 0x00u, 0x01u, 0x6au, 0x06u, 0x00u,
//            0xc3u, 0x9au, 0x00u, 0x01u, 0x09u, 0x98u, 0x00u, 0xf0u,
//            0x07u, 0x47u, 0x01u, 0xbau, 0x07u, 0x09u, 0x27u, 0x08u,
//            0xbfu, 0x09u, 0x07u, 0x77u, 0x07u, 0x00u, 0x80u, 0x47u,
//            0x00u, 0x98u, 0x00u, 0x99u, 0x09u, 0xa7u, 0x09u, 0x09u,
//            0xb8u, 0x09u, 0x00u, 0x05u,
//        )
//    }
}

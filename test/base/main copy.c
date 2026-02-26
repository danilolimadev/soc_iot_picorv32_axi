#include <stdint.h>

#define I2C_BASE    0x40000000
#define I2C_DATA    (*(volatile uint32_t*)(I2C_BASE + 0x00))  // Registrador de dado
#define I2C_STATUS  (*(volatile uint32_t*)(I2C_BASE + 0x04))  // Bit0 = busy

// envia 1 byte para I2C e aguarda transmissão terminar
void i2c_send_wait(uint8_t b)
{
    // espera módulo ficar pronto (busy=0)
    while (I2C_STATUS & 0x1); 

    // escreve o byte no registrador
    I2C_DATA = b;

    // aguarda transmissão completar (busy=1 -> 0)
    while (I2C_STATUS & 0x1);
}

// envia um array de bytes para um dispositivo I2C
void i2c_send_bytes(uint8_t device_addr, uint8_t *data, uint32_t len)
{
    // envia endereço do dispositivo (com bit R/W = 0 para write)
    i2c_send_wait(device_addr << 1);  

    // envia cada byte do buffer
    for (uint32_t i = 0; i < len; i++)
        i2c_send_wait(data[i]);
}

int main()
{
    uint8_t data_seq[] = { 0x11, 0x22, 0x33 };

    // envia endereço 0x42 e depois os dados sequenciais
    i2c_send_bytes(0x42, data_seq, sizeof(data_seq));

    while (1);
}
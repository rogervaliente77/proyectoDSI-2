import consumer from "./consumer";

console.log("✅ Archivo delivery_status_channel.js cargado")

document.addEventListener("DOMContentLoaded", () => {
  const wrapper = document.getElementById("delivery-status-wrapper");

  if (wrapper) {
    const saleId = wrapper.dataset.saleId; // <div id="delivery-status-wrapper" data-sale-id="...">

    consumer.subscriptions.create(
      { channel: "DeliveryStatusChannel", sale_id: saleId },
      {
        received(data) {
          // Reemplaza el contenido completo del partial
          wrapper.innerHTML = data.html;
        }
      }
    );
  }
});
